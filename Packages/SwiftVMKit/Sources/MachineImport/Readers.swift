import Foundation

// MARK: UTM

enum UTMReader {
    static func read(_ url: URL) -> ImportCandidate? {
        guard let data = try? Data(contentsOf: url.appending(path: "config.plist")),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }
        let info = plist["Information"] as? [String: Any] ?? [:]
        let system = plist["System"] as? [String: Any] ?? [:]
        let backend = plist["Backend"] as? String ?? "QEMU"
        let name = info["Name"] as? String ?? url.deletingPathExtension().lastPathComponent
        let architecture = normalized(system["Architecture"] as? String ?? "")
        var notes: [String] = []
        var verdict = ImportCandidate.Verdict.compatible

        var family = "other"
        var auxiliary: String?
        if backend == "Apple" {
            let boot = system["Boot"] as? [String: Any] ?? [:]
            family = (boot["OperatingSystem"] as? String ?? "").lowercased() == "macos" ? "macOS" : "linux"
            if let platform = system["MacPlatform"] as? [String: Any] {
                auxiliary = platform["AuxiliaryStoragePath"] as? String
                if platform["HardwareModel"] == nil || platform["MachineIdentifier"] == nil {
                    verdict = .unsupported
                    notes.append("The machine has no hardware model or identifier: it was never installed.")
                }
            }
        } else {
            family = MachineScanner.family(fromGuestHint: "\(info["Icon"] as? String ?? "") \(name)")
        }

        var disks: [ImportDisk] = []
        for drive in plist["Drive"] as? [[String: Any]] ?? [] {
            guard let image = drive["ImageName"] as? String else { continue }
            if (drive["ImageType"] as? String ?? "Disk") != "Disk" { continue }   // discs aren't disks
            let file = [url.appending(path: "Data/\(image)"), url.appending(path: "Images/\(image)")]
                .first { FileManager.default.fileExists(atPath: $0.path) }
            guard let file else { continue }
            disks.append(ImportDisk(path: file.path, format: MachineScanner.diskFormat(of: file), capacity: MachineScanner.fileSize(file)))
        }
        if disks.isEmpty, verdict == .compatible {
            verdict = .unsupported
            notes.append("The machine has no disk.")
        }

        var candidate = ImportCandidate(
            source: .utm, path: url.path, name: name, family: family, architecture: architecture,
            cpuCount: (system["CPUCount"] as? Int).flatMap { $0 > 0 ? $0 : nil }, memoryMegabytes: system["MemorySize"] as? Int,
            disks: disks, verdict: verdict, notes: notes, auxiliaryStoragePath: auxiliary
        )
        MachineScanner.apply(architecture: architecture, to: &candidate)
        if backend != "Apple", candidate.verdict == .compatible, candidate.family == "other" {
            candidate.notes.append("The system couldn't be told: it is imported as a Linux machine.")
        }
        return candidate
    }

    static func normalized(_ architecture: String) -> String {
        switch architecture.lowercased() {
        case "aarch64", "arm64": "arm64"
        case "x86_64", "i386", "i686": "x86_64"
        case "ppc", "ppc64": "ppc"
        case "": "arm64"   // Apple's virtualization has only ARM64 machines
        default: architecture.lowercased()
        }
    }
}

// MARK: VirtualBox

enum VirtualBoxReader {
    static func read(_ url: URL) -> ImportCandidate? {
        guard let document = try? XMLDocument(contentsOf: url, options: []),
              let machine = (try? document.nodes(forXPath: "//*[local-name()='Machine']"))?.first as? XMLElement else { return nil }
        let name = machine.attribute(forName: "name")?.stringValue ?? url.deletingPathExtension().lastPathComponent
        let osType = machine.attribute(forName: "OSType")?.stringValue ?? ""
        let architecture = osType.lowercased().hasSuffix("_arm64") || osType.lowercased().contains("arm") ? "arm64" : "x86_64"
        let cpu = (try? document.nodes(forXPath: "//*[local-name()='CPU']"))?.first as? XMLElement
        let memory = (try? document.nodes(forXPath: "//*[local-name()='Memory']"))?.first as? XMLElement

        // The disks are in the registry of media, by identifier, and attached by it.
        var locations: [String: String] = [:]
        for node in (try? document.nodes(forXPath: "//*[local-name()='HardDisk']")) ?? [] {
            guard let element = node as? XMLElement, let id = element.attribute(forName: "uuid")?.stringValue,
                  let location = element.attribute(forName: "location")?.stringValue else { continue }
            locations[id.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))] = location
        }
        var disks: [ImportDisk] = []
        for node in (try? document.nodes(forXPath: "//*[local-name()='AttachedDevice'][@type='HardDisk']/*[local-name()='Image']")) ?? [] {
            guard let id = (node as? XMLElement)?.attribute(forName: "uuid")?.stringValue?.trimmingCharacters(in: CharacterSet(charactersIn: "{}")),
                  let location = locations[id] else { continue }
            let file = location.hasPrefix("/") ? URL(filePath: location) : url.deletingLastPathComponent().appending(path: location)
            guard FileManager.default.fileExists(atPath: file.path) else { continue }
            disks.append(ImportDisk(path: file.path, format: MachineScanner.diskFormat(of: file), capacity: nil))
        }
        var candidate = ImportCandidate(
            source: .virtualBox, path: url.path, name: name, family: MachineScanner.family(fromGuestHint: osType), architecture: architecture,
            cpuCount: cpu?.attribute(forName: "count")?.stringValue.flatMap(Int.init) ?? 1,
            memoryMegabytes: memory?.attribute(forName: "RAMSize")?.stringValue.flatMap(Int.init), disks: disks,
            notes: ["Remove VirtualBox's Guest Additions in the guest if it misbehaves."]
        )
        if disks.isEmpty {
            candidate.verdict = .unsupported
            candidate.notes.append("None of the machine's disks was found next to it.")
        }
        MachineScanner.apply(architecture: architecture, to: &candidate)
        return candidate
    }
}

// MARK: VMware Fusion

enum VMwareReader {
    static func read(package: URL) -> ImportCandidate? {
        let items = (try? FileManager.default.contentsOfDirectory(at: package, includingPropertiesForKeys: nil)) ?? []
        guard let vmx = items.first(where: { $0.pathExtension == "vmx" }) else { return nil }
        return read(vmx: vmx, reportedAs: package)
    }

    static func read(vmx: URL, reportedAs path: URL? = nil) -> ImportCandidate? {
        guard let text = try? String(contentsOf: vmx, encoding: .utf8) else { return nil }
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            values[parts[0].lowercased()] = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        let guest = values["guestos"] ?? ""
        let architecture = guest.lowercased().hasPrefix("arm-") || guest.lowercased().contains("arm64") ? "arm64" : "x86_64"
        let folder = vmx.deletingLastPathComponent()
        var disks: [ImportDisk] = []
        for (key, value) in values.sorted(by: { $0.key < $1.key }) where key.hasSuffix(".filename") && value.lowercased().hasSuffix(".vmdk") {
            // sata0:0.filename, nvme0:0.filename, scsi0:0.filename: controllers' disks. Not optical drives.
            guard key.contains(":"), values[key.replacingOccurrences(of: ".filename", with: ".devicetype")]?.contains("cdrom") != true else { continue }
            let file = value.hasPrefix("/") ? URL(filePath: value) : folder.appending(path: value)
            guard FileManager.default.fileExists(atPath: file.path) else { continue }
            disks.append(ImportDisk(path: file.path, format: "vmdk", capacity: nil))
        }
        var candidate = ImportCandidate(
            source: .fusion, path: (path ?? vmx).path, name: values["displayname"] ?? vmx.deletingPathExtension().lastPathComponent,
            family: MachineScanner.family(fromGuestHint: guest), architecture: architecture,
            cpuCount: values["numvcpus"].flatMap(Int.init) ?? 1, memoryMegabytes: values["memsize"].flatMap(Int.init), disks: disks,
            notes: ["Remove VMware Tools in the guest if it misbehaves. Windows needs its NVMe or VirtIO drivers, which it has."]
        )
        if disks.isEmpty {
            candidate.verdict = .unsupported
            candidate.notes.append("None of the machine's disks was found next to it.")
        }
        MachineScanner.apply(architecture: architecture, to: &candidate)
        return candidate
    }
}

// MARK: Parallels Desktop

enum ParallelsReader {
    static func read(_ url: URL) -> ImportCandidate? {
        guard let document = try? XMLDocument(contentsOf: url.appending(path: "config.pvs"), options: []) else { return nil }
        func text(_ path: String) -> String? {
            ((try? document.nodes(forXPath: path))?.first)?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let name = text("//Identification/VmName") ?? url.deletingPathExtension().lastPathComponent
        let guest = [text("//GuestOSType"), text("//OsVersion"), text("//Settings/General/OsType")].compactMap { $0 }.joined(separator: " ")
        let architecture = (text("//Architecture") ?? text("//Settings/General/Architecture") ?? "").lowercased().contains("arm")
            || guest.lowercased().contains("arm") ? "arm64" : "x86_64"
        var disks: [ImportDisk] = []
        for node in (try? document.nodes(forXPath: "//Hdd/SystemName")) ?? [] {
            guard let name = node.stringValue else { continue }
            let hdd = url.appending(path: name)
            // The disk is a folder of `.hds` files, which the descriptor lists.
            let parts = ((try? FileManager.default.contentsOfDirectory(at: hdd, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.pathExtension == "hds" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            if let first = parts.first {
                disks.append(ImportDisk(path: first.path, format: "parallels", capacity: nil))
            }
        }
        var candidate = ImportCandidate(
            source: .parallels, path: url.path, name: name, family: MachineScanner.family(fromGuestHint: guest), architecture: architecture,
            cpuCount: text("//Cpu/Number").flatMap(Int.init), memoryMegabytes: text("//Memory/RAM").flatMap(Int.init), disks: disks,
            notes: ["Remove Parallels Tools in the guest if it misbehaves."]
        )
        if disks.isEmpty {
            candidate.verdict = .unsupported
            candidate.notes.append("None of the machine's disks was found in it.")
        }
        MachineScanner.apply(architecture: architecture, to: &candidate)
        return candidate
    }
}
