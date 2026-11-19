// Généré par catalog/embed.py à partir de catalog/catalogue.json : ne pas modifier à la main.
import Foundation

/// The catalogue that comes with the app, for a start without a network and as a floor under what is downloaded.
nonisolated enum DiscoveryFallback {
    static let catalog: DiscoveryCatalog = {
        // The embedded file is checked by the tests; an unreadable one would leave the window empty.
        (try? DiscoveryCatalog.decode(Data(json.utf8))) ?? DiscoveryCatalog(schema: 1, revision: 0, updatedAt: "", entries: [])
    }()

    static let json = #"""
{
  "schema": 1,
  "revision": 5,
  "updatedAt": "2026-11-19",
  "entries": [
    {
      "id": "freebsd",
      "name": "FreeBSD",
      "family": "bsd",
      "summary": {
        "en": "The reference BSD: a complete, coherent system with ZFS, jails and the bhyve heritage. Installer disc image (disc1), latest stable release.",
        "fr": "Le BSD de référence : un système complet et cohérent, avec ZFS, les jails et l'héritage bhyve. Image d'installation (disc1), dernière version stable.",
        "es": "El BSD de referencia: un sistema completo y coherente, con ZFS, jails y la herencia de bhyve. Imagen de instalación (disc1), última versión estable.",
        "it": "Il BSD di riferimento: un sistema completo e coerente, con ZFS, jail e l'eredità di bhyve. Immagine di installazione (disc1), ultima versione stabile."
      },
      "tags": [
        "unix",
        "server",
        "experimental"
      ],
      "featured": false,
      "color": "#c0392b",
      "defaults": {
        "cpuCount": 4,
        "memoryGB": 4,
        "diskGB": 32,
        "engine": "qemu"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://download.freebsd.org/releases/arm64/aarch64/ISO-IMAGES/",
        "dirPattern": "[0-9]+\\.[0-9]+/",
        "filePattern": "FreeBSD-[0-9.]+-RELEASE-arm64-aarch64-disc1\\.iso",
        "versionPattern": "FreeBSD-([0-9.]+)-RELEASE",
        "checksum": {
          "url": "{base}CHECKSUM.SHA256-FreeBSD-{dir}-RELEASE-arm64-aarch64",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "15.1",
        "url": "https://download.freebsd.org/releases/arm64/aarch64/ISO-IMAGES/15.1/FreeBSD-15.1-RELEASE-arm64-aarch64-disc1.iso",
        "algorithm": "sha256",
        "digest": "e17805c6e5a1323d4a31919053b7b2b25876344f2fada3762a4d8009770f1d7f",
        "bytes": 1196779520,
        "date": "2026-06-12"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/FreeBSD_11.1_with_XFCE_desktop_environment_2017-Oct-04_00-57-49.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:FreeBSD_11.1_with_XFCE_desktop_environment_2017-Oct-04_00-57-49.png"
      }
    },
    {
      "id": "openbsd",
      "name": "OpenBSD",
      "family": "bsd",
      "summary": {
        "en": "The security-first BSD: clean code, sane defaults, pf firewall and a very small, readable base system. Installer disc image.",
        "fr": "Le BSD centré sur la sécurité : code propre, réglages sains, pare-feu pf et un système de base petit et lisible. Image d'installation.",
        "es": "El BSD centrado en la seguridad: código limpio, ajustes sensatos, cortafuegos pf y un sistema base pequeño y legible. Imagen de instalación.",
        "it": "Il BSD orientato alla sicurezza: codice pulito, impostazioni sensate, firewall pf e un sistema base piccolo e leggibile. Immagine di installazione."
      },
      "tags": [
        "unix",
        "security",
        "light"
      ],
      "featured": false,
      "color": "#e5b80b",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 24,
        "engine": "qemu"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://cdn.openbsd.org/pub/OpenBSD/",
        "dirPattern": "[0-9]+\\.[0-9]+/",
        "subpath": "arm64/",
        "filePattern": "install[0-9]+\\.iso",
        "versionPattern": "install([0-9]+)\\.iso",
        "versionDotted": true,
        "checksum": {
          "url": "{base}SHA256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "8.0",
        "url": "https://cdn.openbsd.org/pub/OpenBSD/8.0/arm64/install80.iso",
        "algorithm": "sha256",
        "digest": "6449a657d021e000cebb50987535b3dec6988edc65908107b42a42c2f95c3f6b",
        "bytes": 656941056,
        "date": "2026-10-07"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/OpenBSD_7.0_fvwm_screenshot.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:OpenBSD_7.0_fvwm_screenshot.png"
      }
    },
    {
      "id": "netbsd",
      "name": "NetBSD",
      "family": "bsd",
      "summary": {
        "en": "“Of course it runs NetBSD”: the most portable Unix, tiny and tidy, a joy to explore. Installer disc image for ARM64.",
        "fr": "« Bien sûr que ça tourne sous NetBSD » : l'Unix le plus portable, minuscule et soigné, un plaisir à explorer. Image d'installation ARM64.",
        "es": "«Por supuesto que corre NetBSD»: el Unix más portable, diminuto y cuidado, un placer para explorar. Imagen de instalación ARM64.",
        "it": "«Certo che gira NetBSD»: l'Unix più portabile, minuscolo e curato, un piacere da esplorare. Immagine di installazione ARM64."
      },
      "tags": [
        "unix",
        "light",
        "retro"
      ],
      "featured": false,
      "color": "#e67e22",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 24,
        "engine": "qemu"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://cdn.netbsd.org/pub/NetBSD/",
        "dirPattern": "NetBSD-[0-9.]+/",
        "subpath": "images/",
        "filePattern": "NetBSD-[0-9.]+-evbarm-aarch64\\.iso",
        "versionPattern": "NetBSD-([0-9.]+)-evbarm",
        "checksum": {
          "url": "{base}SHA512",
          "algorithm": "sha512"
        }
      },
      "snapshot": {
        "version": "11.1",
        "url": "https://cdn.netbsd.org/pub/NetBSD/NetBSD-11.1/images/NetBSD-11.1-evbarm-aarch64.iso",
        "algorithm": "sha512",
        "digest": "f049cbf2a8a706ee3d975037bd44d65720de215681020eacaa7696ddd53cc3373952a2a003d3571effc859dcb65918dd7020d16fcff4fa959b34555a0ba5d642",
        "bytes": 295620608,
        "date": "2026-11-02"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/A_Screenshot_In_NetBSD_10.1_Xorg1.20.14_With_Every_Desktop_Utilities_And_xterm_Windows_Open.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:A_Screenshot_In_NetBSD_10.1_Xorg1.20.14_With_Every_Desktop_Utilities_And_xterm_Windows_Open.png"
      }
    },
    {
      "id": "alpine",
      "name": "Alpine Linux",
      "family": "linux",
      "summary": {
        "en": "Tiny, fast and secure (musl, BusyBox, OpenRC). The “virt” image is built for virtual machines and boots in seconds.",
        "fr": "Minuscule, rapide et sûre (musl, BusyBox, OpenRC). L'image « virt » est conçue pour les machines virtuelles et démarre en quelques secondes.",
        "es": "Diminuta, rápida y segura (musl, BusyBox, OpenRC). La imagen «virt» está pensada para máquinas virtuales y arranca en segundos.",
        "it": "Minuscola, veloce e sicura (musl, BusyBox, OpenRC). L'immagine «virt» è pensata per le macchine virtuali e si avvia in pochi secondi."
      },
      "tags": [
        "light",
        "server",
        "containers"
      ],
      "featured": false,
      "color": "#0d597f",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 1,
        "diskGB": 8,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/",
        "filePattern": "alpine-virt-[0-9.]+-aarch64\\.iso",
        "versionPattern": "alpine-virt-([0-9.]+)-",
        "checksum": {
          "url": "{base}{file}.sha256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "3.24.4",
        "url": "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/alpine-virt-3.24.4-aarch64.iso",
        "algorithm": "sha256",
        "digest": "cf88d8ba67389d20d9ed307366b52e487c15d7d3ee3233b62b95f709daa1d430",
        "bytes": 93464576,
        "date": "2026-11-05"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Alpine_Linux_Xfce_-_English.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Alpine_Linux_Xfce_-_English.png"
      }
    },
    {
      "id": "debian",
      "name": "Debian",
      "family": "linux",
      "summary": {
        "en": "The universal operating system: stable, conservative, the base of countless distributions. Network installer, latest stable release.",
        "fr": "Le système d'exploitation universel : stable, prudent, la base d'innombrables distributions. Installateur réseau, dernière version stable.",
        "es": "El sistema operativo universal: estable, prudente, la base de innumerables distribuciones. Instalador de red, última versión estable.",
        "it": "Il sistema operativo universale: stabile, prudente, la base di innumerevoli distribuzioni. Installer di rete, ultima versione stabile."
      },
      "tags": [
        "server",
        "desktop"
      ],
      "featured": false,
      "color": "#c2185b",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 20,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/",
        "filePattern": "debian-[0-9.]+-arm64-netinst\\.iso",
        "versionPattern": "debian-([0-9.]+)-arm64",
        "checksum": {
          "url": "{base}SHA256SUMS",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "13.7.0",
        "url": "https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-13.7.0-arm64-netinst.iso",
        "algorithm": "sha256",
        "digest": "6e93fa1759bd9d4b0fc11e938987de6967ee7de5297dac1be27c3a75cc17024b",
        "bytes": 735358976,
        "date": "2026-09-12"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Debian_13_%28Trixie%29_screenshot_-_using_GNOME_desktop.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Debian_13_%28Trixie%29_screenshot_-_using_GNOME_desktop.png"
      }
    },
    {
      "id": "nixos",
      "name": "NixOS",
      "family": "linux",
      "summary": {
        "en": "Declarative Linux: the whole system is described in one configuration file, upgrades are atomic and rollbacks are free. Minimal installer.",
        "fr": "Linux déclaratif : tout le système se décrit dans un fichier de configuration, les mises à jour sont atomiques et le retour arrière est gratuit. Installateur minimal.",
        "es": "Linux declarativo: todo el sistema se describe en un archivo de configuración, las actualizaciones son atómicas y volver atrás es gratis. Instalador mínimo.",
        "it": "Linux dichiarativo: l'intero sistema è descritto in un file di configurazione, gli aggiornamenti sono atomici e il ritorno indietro è gratuito. Installer minimale."
      },
      "tags": [
        "experimental",
        "server",
        "desktop"
      ],
      "featured": true,
      "color": "#5277c3",
      "rotationDate": "2026-11-19",
      "defaults": {
        "cpuCount": 4,
        "memoryGB": 4,
        "diskGB": 40,
        "engine": "virtualization"
      },
      "source": {
        "kind": "fixed",
        "url": "https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-aarch64-linux.iso",
        "versionPattern": "nixos-minimal-([0-9]+\\.[0-9]+)",
        "checksum": {
          "url": "{url}.sha256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "26.05",
        "url": "https://releases.nixos.org/nixos/26.05/nixos-26.05.14630.f68407657ad2/nixos-minimal-26.05.14630.f68407657ad2-aarch64-linux.iso",
        "algorithm": "sha256",
        "digest": "355cce22d8fa67d9c90d1f712327de4514cd091a3702e6c4732f7b4354e89825",
        "bytes": 1822398464,
        "date": "2026-11-17"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/NixOS_21.11_GNOME_main_menu_-_English.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:NixOS_21.11_GNOME_main_menu_-_English.png"
      }
    },
    {
      "id": "opensuse-tumbleweed",
      "name": "openSUSE Tumbleweed",
      "family": "linux",
      "summary": {
        "en": "A tested rolling release: always up to date, with the KDE Plasma desktop in a live session you can try before installing.",
        "fr": "Une rolling release testée : toujours à jour, avec le bureau KDE Plasma en session live à essayer avant d'installer.",
        "es": "Una rolling release probada: siempre al día, con el escritorio KDE Plasma en sesión live para probar antes de instalar.",
        "it": "Una rolling release testata: sempre aggiornata, con il desktop KDE Plasma in sessione live da provare prima di installare."
      },
      "tags": [
        "rolling",
        "desktop"
      ],
      "featured": false,
      "color": "#2fa34a",
      "defaults": {
        "cpuCount": 4,
        "memoryGB": 4,
        "diskGB": 40,
        "engine": "virtualization"
      },
      "source": {
        "kind": "fixed",
        "url": "https://download.opensuse.org/ports/aarch64/tumbleweed/iso/openSUSE-Tumbleweed-KDE-Live-aarch64-Current.iso",
        "versionPattern": "Snapshot([0-9]+)",
        "checksum": {
          "url": "{url}.sha256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "20261117",
        "url": "https://downloadcontent.opensuse.org/ports/aarch64/tumbleweed/iso/openSUSE-Tumbleweed-KDE-Live-aarch64-Snapshot20261117-Media.iso",
        "algorithm": "sha256",
        "digest": "5bd3c2db7a460c551ad0ab411eda3e13f4f9276f5f068681f0a1b391c76ff00b",
        "bytes": 1467299840,
        "date": "2026-11-18"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/OpenSUSE_Tumbleweed_in_KDE_6.jpg?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:OpenSUSE_Tumbleweed_in_KDE_6.jpg"
      }
    },
    {
      "id": "kali",
      "name": "Kali Linux",
      "family": "linux",
      "summary": {
        "en": "The security professional's toolbox: hundreds of penetration-testing and forensics tools. Use it only on systems you own or are allowed to test.",
        "fr": "La boîte à outils du professionnel de la sécurité : des centaines d'outils de test d'intrusion et d'analyse forensique. À n'utiliser que sur des systèmes qui vous appartiennent ou que vous avez le droit de tester.",
        "es": "La caja de herramientas del profesional de la seguridad: cientos de herramientas de pruebas de intrusión y análisis forense. Úsela solo en sistemas propios o que tenga permiso para probar.",
        "it": "La cassetta degli attrezzi del professionista della sicurezza: centinaia di strumenti di penetration testing e analisi forense. Da usare solo su sistemi propri o che si ha il permesso di testare."
      },
      "tags": [
        "security",
        "desktop"
      ],
      "featured": false,
      "color": "#367bf0",
      "defaults": {
        "cpuCount": 4,
        "memoryGB": 4,
        "diskGB": 50,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://cdimage.kali.org/current/",
        "filePattern": "kali-linux-[0-9.]+-installer-arm64\\.iso",
        "versionPattern": "kali-linux-([0-9.]+)-",
        "checksum": {
          "url": "{base}SHA256SUMS",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "2026.3",
        "url": "https://cdimage.kali.org/current/kali-linux-2026.3-installer-arm64.iso",
        "algorithm": "sha256",
        "digest": "c4a7f9bf3a0ff07c8263fe9e9b0edba0cc3d9b408f1d8f06c066df0afce23072",
        "bytes": 4051513344,
        "date": "2026-10-09"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Kali-screenshot-20221021.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Kali-screenshot-20221021.png"
      }
    },
    {
      "id": "chimera",
      "name": "Chimera Linux",
      "family": "linux",
      "summary": {
        "en": "An unusual Linux: LLVM toolchain, musl, FreeBSD userland, dinit and apk. Modern, clean and fun to explore. Base live image.",
        "fr": "Un Linux singulier : chaîne LLVM, musl, outils FreeBSD, dinit et apk. Moderne, propre et amusant à explorer. Image live de base.",
        "es": "Un Linux singular: cadena LLVM, musl, herramientas de FreeBSD, dinit y apk. Moderno, limpio y divertido de explorar. Imagen live base.",
        "it": "Un Linux insolito: toolchain LLVM, musl, userland FreeBSD, dinit e apk. Moderno, pulito e divertente da esplorare. Immagine live di base."
      },
      "tags": [
        "experimental",
        "light"
      ],
      "featured": false,
      "color": "#8e44ad",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 20,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://repo.chimera-linux.org/live/latest/",
        "filePattern": "chimera-linux-aarch64-LIVE-[0-9]+-base\\.iso",
        "versionPattern": "LIVE-([0-9]+)-",
        "checksum": {
          "url": "{base}sha256sums.txt",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "20261103",
        "url": "https://repo.chimera-linux.org/live/latest/chimera-linux-aarch64-LIVE-20261103-base.iso",
        "algorithm": "sha256",
        "digest": "b45f052e077359d9c9366a57ada066a9700929542dfc968a3e5d7634ba09ec63",
        "bytes": 1479243776,
        "date": "2026-11-03"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Chimera_Linux_GNOME_-_English.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Chimera_Linux_GNOME_-_English.png"
      }
    },
    {
      "id": "fedora-coreos",
      "name": "Fedora CoreOS",
      "family": "linux",
      "summary": {
        "en": "An immutable, auto-updating OS built to run containers, configured at first boot with Ignition. Live ISO, stable stream.",
        "fr": "Un système immuable et à mise à jour automatique, conçu pour exécuter des conteneurs, configuré au premier démarrage avec Ignition. ISO live, flux stable.",
        "es": "Un sistema inmutable y de actualización automática, creado para ejecutar contenedores, configurado en el primer arranque con Ignition. ISO live, flujo estable.",
        "it": "Un sistema immutabile e ad aggiornamento automatico, pensato per eseguire container, configurato al primo avvio con Ignition. ISO live, flusso stabile."
      },
      "tags": [
        "containers",
        "server",
        "experimental"
      ],
      "featured": false,
      "color": "#294172",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 16,
        "engine": "virtualization"
      },
      "source": {
        "kind": "json",
        "jsonURL": "https://builds.coreos.fedoraproject.org/streams/stable.json",
        "urlPath": "architectures.aarch64.artifacts.metal.formats.iso.disk.location",
        "sha256Path": "architectures.aarch64.artifacts.metal.formats.iso.disk.sha256",
        "versionPath": "architectures.aarch64.artifacts.metal.release"
      },
      "snapshot": {
        "version": "44.20261023.3.1",
        "url": "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/44.20261023.3.1/aarch64/fedora-coreos-44.20261023.3.1-live-iso.aarch64.iso",
        "algorithm": "sha256",
        "digest": "2efbc126bf9b1fe296794d793e19e9ae62684a28a8e2461a5f6bb269a81f7392",
        "bytes": 880181248,
        "date": "2026-10-31"
      }
    },
    {
      "id": "rocky",
      "name": "Rocky Linux",
      "family": "linux",
      "summary": {
        "en": "A community enterprise Linux, binary-compatible with Red Hat Enterprise Linux. Boot (network install) image, latest major release.",
        "fr": "Un Linux d'entreprise communautaire, compatible binaire avec Red Hat Enterprise Linux. Image de démarrage (installation réseau), dernière version majeure.",
        "es": "Un Linux empresarial comunitario, compatible a nivel binario con Red Hat Enterprise Linux. Imagen de arranque (instalación por red), última versión mayor.",
        "it": "Un Linux enterprise della comunità, compatibile a livello binario con Red Hat Enterprise Linux. Immagine di avvio (installazione di rete), ultima versione principale."
      },
      "tags": [
        "server"
      ],
      "featured": false,
      "color": "#10b981",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 20,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://dl.rockylinux.org/pub/rocky/",
        "dirPattern": "[0-9]+/",
        "subpath": "isos/aarch64/",
        "filePattern": "Rocky-[0-9.]+-aarch64-boot\\.iso",
        "versionPattern": "Rocky-([0-9.]+)-",
        "checksum": {
          "url": "{base}{file}.CHECKSUM",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "10.3",
        "url": "https://dl.rockylinux.org/pub/rocky/10/isos/aarch64/Rocky-10.3-aarch64-boot.iso",
        "algorithm": "sha256",
        "digest": "3713f3f4a782c94ecd239c6f756cb18d8a9a287dbf4c5f44e6ad13c8e1b3af6e",
        "bytes": 1062293504,
        "date": "2026-11-12"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Rocky_Linux_8.4_Workstation_Application_picker_screenshot.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Rocky_Linux_8.4_Workstation_Application_picker_screenshot.png"
      }
    },
    {
      "id": "almalinux",
      "name": "AlmaLinux",
      "family": "linux",
      "summary": {
        "en": "Another community RHEL-compatible enterprise Linux, backed by the AlmaLinux OS Foundation. Boot (network install) image.",
        "fr": "Un autre Linux d'entreprise communautaire compatible RHEL, soutenu par l'AlmaLinux OS Foundation. Image de démarrage (installation réseau).",
        "es": "Otro Linux empresarial comunitario compatible con RHEL, respaldado por la AlmaLinux OS Foundation. Imagen de arranque (instalación por red).",
        "it": "Un altro Linux enterprise della comunità compatibile con RHEL, sostenuto dalla AlmaLinux OS Foundation. Immagine di avvio (installazione di rete)."
      },
      "tags": [
        "server"
      ],
      "featured": false,
      "color": "#0ea5e9",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 20,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://repo.almalinux.org/almalinux/",
        "dirPattern": "[0-9]+/",
        "subpath": "isos/aarch64/",
        "filePattern": "AlmaLinux-[0-9.]+-aarch64-boot\\.iso",
        "versionPattern": "AlmaLinux-([0-9.]+)-",
        "checksum": {
          "url": "{base}CHECKSUM",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "10.3",
        "url": "https://repo.almalinux.org/almalinux/10/isos/aarch64/AlmaLinux-10.3-aarch64-boot.iso",
        "algorithm": "sha256",
        "digest": "3bf0f44bd2c9c75eb02a1795c7253c29926d189e13bc53d0f78673ab4929b1fd",
        "bytes": 1069295616,
        "date": "2026-11-13"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/AlmaLinux_9.3_Xfce_default_desktop_-_English.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:AlmaLinux_9.3_Xfce_default_desktop_-_English.png"
      }
    },
    {
      "id": "gentoo",
      "name": "Gentoo Linux",
      "family": "linux",
      "summary": {
        "en": "The source-based, fully customisable Linux: you build your system the way you want it, with Portage. Minimal installation image (a console install, for the curious).",
        "fr": "Le Linux compilé depuis les sources et entièrement personnalisable : vous construisez votre système comme vous le voulez, avec Portage. Image d'installation minimale (installation en console, pour les curieux).",
        "es": "El Linux basado en código fuente y totalmente personalizable: construye su sistema como quiere, con Portage. Imagen de instalación mínima (instalación en consola, para curiosos).",
        "it": "Il Linux basato sui sorgenti e completamente personalizzabile: costruisci il sistema come vuoi, con Portage. Immagine di installazione minimale (installazione da console, per i curiosi)."
      },
      "tags": [
        "experimental",
        "desktop",
        "server"
      ],
      "featured": false,
      "color": "#54487a",
      "defaults": {
        "cpuCount": 4,
        "memoryGB": 4,
        "diskGB": 60,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://distfiles.gentoo.org/releases/arm64/autobuilds/",
        "dirPattern": "[0-9]{8}T[0-9]{6}Z/",
        "filePattern": "install-arm64-minimal-[0-9]{8}T[0-9]{6}Z\\.iso",
        "versionPattern": "minimal-([0-9]{8})T",
        "checksum": {
          "url": "{base}{file}.sha256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "20261115",
        "url": "https://distfiles.gentoo.org/releases/arm64/autobuilds/20261115T234600Z/install-arm64-minimal-20261115T234600Z.iso",
        "algorithm": "sha256",
        "digest": "a055e6164c67f3ec4c09750a5317ba0506ef61f0c741b51054d77329cc8abff9",
        "bytes": 866953216,
        "date": "2026-11-16"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Gnome-Desktop_%28Gentoo-Linux%29.jpg?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Gnome-Desktop_%28Gentoo-Linux%29.jpg"
      }
    },
    {
      "id": "centos-stream",
      "name": "CentOS Stream",
      "family": "linux",
      "summary": {
        "en": "The rolling preview of the next Red Hat Enterprise Linux minor release: enterprise Linux, one step ahead. Boot (network install) image, Stream 10.",
        "fr": "L'aperçu continu de la prochaine version de Red Hat Enterprise Linux : un Linux d'entreprise, une longueur d'avance. Image de démarrage (installation réseau), Stream 10.",
        "es": "La vista previa continua de la próxima versión de Red Hat Enterprise Linux: Linux empresarial, un paso por delante. Imagen de arranque (instalación por red), Stream 10.",
        "it": "L'anteprima continua della prossima versione di Red Hat Enterprise Linux: Linux enterprise, un passo avanti. Immagine di avvio (installazione di rete), Stream 10."
      },
      "tags": [
        "server",
        "rolling"
      ],
      "featured": false,
      "color": "#932279",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 20,
        "engine": "virtualization"
      },
      "source": {
        "kind": "listing",
        "indexURL": "https://mirror.stream.centos.org/10-stream/BaseOS/aarch64/iso/",
        "filePattern": "CentOS-Stream-10-[0-9.]+-aarch64-boot\\.iso",
        "versionPattern": "CentOS-Stream-(10-[0-9.]+)-aarch64",
        "checksum": {
          "url": "{base}{file}.SHA256SUM",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "10-20261118.0",
        "url": "https://mirror.stream.centos.org/10-stream/BaseOS/aarch64/iso/CentOS-Stream-10-20261118.0-aarch64-boot.iso",
        "algorithm": "sha256",
        "digest": "fe2d97beef5a0fcd5ee28804eb2c9e0e85cfb79ae1ff9d06cdda0045149dbe7b",
        "bytes": 1058836480,
        "date": "2026-11-18"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/CentOS_Stream_9_Cinnamon_GNOME_Terminal_3.40.3_-_English.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:CentOS_Stream_9_Cinnamon_GNOME_Terminal_3.40.3_-_English.png"
      }
    },
    {
      "id": "haiku",
      "name": "Haiku",
      "family": "other",
      "summary": {
        "en": "The open-source heir of BeOS: a fast, coherent desktop built from scratch, with its own filesystem and a charming 90s design. The ARM64 port is experimental, from the daily build.",
        "fr": "L'héritier libre de BeOS : un bureau rapide et cohérent, écrit de zéro, avec son propre système de fichiers et un charme des années 90. Le portage ARM64 est expérimental, issu de la version du jour.",
        "es": "El heredero libre de BeOS: un escritorio rápido y coherente, escrito desde cero, con su propio sistema de archivos y el encanto de los años 90. El port ARM64 es experimental, de la compilación del día.",
        "it": "L'erede libero di BeOS: un desktop veloce e coerente, scritto da zero, con un filesystem proprio e il fascino degli anni '90. Il port ARM64 è sperimentale, dalla build del giorno."
      },
      "tags": [
        "unusual",
        "desktop",
        "retro",
        "experimental"
      ],
      "featured": false,
      "color": "#e8a317",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 2,
        "diskGB": 8,
        "engine": "qemu",
        "diskBus": "usb"
      },
      "source": {
        "kind": "listing",
        "archive": "zip",
        "member": ".image",
        "media": "disk",
        "absoluteLinks": true,
        "indexURL": "https://download.haiku-os.org/nightly-images/arm64/",
        "filePattern": "haiku-master-hrev[0-9]+-arm64-mmc\\.zip",
        "versionPattern": "(hrev[0-9]+)",
        "checksum": {
          "url": "{url}.sha256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "hrev60437",
        "url": "https://haiku-nightly.cdn.haiku-os.org/arm64/haiku-master-hrev60437-arm64-mmc.zip",
        "algorithm": "sha256",
        "digest": "e838b242881baed20e191107eb3ab5bb26a7692c81b58b4b8a624fa3e2afb13d",
        "bytes": 58819611,
        "date": "2026-11-19"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/Haiku_R1_Beta_3_desktop_screenshot.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:Haiku_R1_Beta_3_desktop_screenshot.png"
      }
    },
    {
      "id": "redox",
      "name": "Redox OS",
      "family": "other",
      "summary": {
        "en": "A Unix-like microkernel system written entirely in Rust, with its own display server and apps. Daily live image with the desktop; experimental on ARM64.",
        "fr": "Un système de type Unix à micronoyau écrit entièrement en Rust, avec son propre serveur d'affichage et ses applications. Image live du jour avec le bureau ; expérimental sur ARM64.",
        "es": "Un sistema tipo Unix con microkernel escrito íntegramente en Rust, con su propio servidor de pantalla y aplicaciones. Imagen live diaria con el escritorio; experimental en ARM64.",
        "it": "Un sistema di tipo Unix a microkernel scritto interamente in Rust, con il proprio server grafico e le proprie app. Immagine live giornaliera con il desktop; sperimentale su ARM64."
      },
      "tags": [
        "unusual",
        "experimental",
        "unix"
      ],
      "featured": false,
      "color": "#d4413a",
      "defaults": {
        "cpuCount": 4,
        "memoryGB": 4,
        "diskGB": 8,
        "engine": "qemu"
      },
      "source": {
        "kind": "listing",
        "archive": "zstd",
        "media": "disc",
        "indexURL": "https://static.redox-os.org/img/aarch64/",
        "filePattern": "redox_desktop_aarch64_[0-9_-]+_livedisk\\.iso\\.zst",
        "versionPattern": "aarch64_([0-9-]+_[0-9]+)_livedisk",
        "checksum": {
          "url": "{base}SHA256SUM",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "2026-11-18_589",
        "url": "https://static.redox-os.org/img/aarch64/redox_desktop_aarch64_2026-11-18_589_livedisk.iso.zst",
        "algorithm": "sha256",
        "digest": "08cbc7cdaf741cab88069e168471219a742321f0846baf60999bce8d8d8f86b2",
        "bytes": 135334251,
        "date": "2026-11-19"
      }
    },
    {
      "id": "openwrt",
      "name": "OpenWrt",
      "family": "linux",
      "summary": {
        "en": "The Linux that runs the world's routers, with its own LuCI web interface. In a virtual machine it becomes a lab router you can break and rebuild. Ready-to-boot disk image.",
        "fr": "Le Linux des routeurs du monde entier, avec sa propre interface web LuCI. Dans une machine virtuelle, c'est un routeur de laboratoire qu'on peut casser et refaire. Image disque prête à démarrer.",
        "es": "El Linux de los routers de medio mundo, con su propia interfaz web LuCI. En una máquina virtual es un router de laboratorio que se puede romper y rehacer. Imagen de disco lista para arrancar.",
        "it": "Il Linux dei router di tutto il mondo, con la propria interfaccia web LuCI. In una macchina virtuale diventa un router da laboratorio che si può rompere e rifare. Immagine disco pronta all'avvio."
      },
      "tags": [
        "unusual",
        "light",
        "server"
      ],
      "featured": false,
      "color": "#00a1e0",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 1,
        "diskGB": 4,
        "engine": "qemu"
      },
      "source": {
        "kind": "listing",
        "archive": "gzip",
        "media": "disk",
        "indexURL": "https://downloads.openwrt.org/releases/",
        "dirPattern": "[0-9]+\\.[0-9]+\\.[0-9]+/",
        "subpath": "targets/armsr/armv8/",
        "filePattern": "openwrt-[0-9.]+-armsr-armv8-generic-ext4-combined-efi\\.img\\.gz",
        "versionPattern": "openwrt-([0-9.]+)-armsr",
        "checksum": {
          "url": "{base}sha256sums",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "25.12.6",
        "url": "https://downloads.openwrt.org/releases/25.12.6/targets/armsr/armv8/openwrt-25.12.6-armsr-armv8-generic-ext4-combined-efi.img.gz",
        "algorithm": "sha256",
        "digest": "77a3802b583a6964ccb868c80f83a6ea0eb5847d3835350b5f0bcbf6f141d1d3",
        "bytes": 14669158,
        "date": "2026-10-18"
      },
      "screenshot": {
        "url": "https://commons.wikimedia.org/wiki/Special:FilePath/LuCI_Interface%2C_OpenWRT_25.12.2.png?width=1040",
        "credit": "Wikimedia Commons",
        "page": "https://commons.wikimedia.org/wiki/File:LuCI_Interface%2C_OpenWRT_25.12.2.png"
      }
    },
    {
      "id": "talos",
      "name": "Talos Linux",
      "family": "linux",
      "summary": {
        "en": "A Linux with no shell, no SSH and no package manager: the whole system is run through an API, built only to run Kubernetes. Impossible to log in to, wonderful to look at.",
        "fr": "Un Linux sans shell, sans SSH et sans gestionnaire de paquets : tout le système se pilote par une API, conçu uniquement pour faire tourner Kubernetes. Impossible de s'y connecter, fascinant à observer.",
        "es": "Un Linux sin shell, sin SSH y sin gestor de paquetes: todo el sistema se controla por una API, creado solo para ejecutar Kubernetes. Imposible iniciar sesión, fascinante de observar.",
        "it": "Un Linux senza shell, senza SSH e senza gestore di pacchetti: l'intero sistema si governa tramite API, creato solo per eseguire Kubernetes. Impossibile accedervi, affascinante da osservare."
      },
      "tags": [
        "unusual",
        "containers",
        "server"
      ],
      "featured": false,
      "color": "#ff7300",
      "defaults": {
        "cpuCount": 2,
        "memoryGB": 4,
        "diskGB": 16,
        "engine": "virtualization"
      },
      "source": {
        "kind": "fixed",
        "url": "https://github.com/siderolabs/talos/releases/latest/download/metal-arm64.iso",
        "checksum": {
          "url": "https://github.com/siderolabs/talos/releases/latest/download/sha256sum.txt",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "2026-11-11",
        "url": "https://github.com/siderolabs/talos/releases/latest/download/metal-arm64.iso",
        "algorithm": "sha256",
        "digest": "40f54686eda7d208164d8eb6c65961bee3542a4820cb52084cfc5eea1c3b193a",
        "bytes": 227848192,
        "date": "2026-11-11"
      }
    }
  ]
}
"""#
}
