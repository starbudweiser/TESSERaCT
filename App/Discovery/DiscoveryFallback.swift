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
  "revision": 2,
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
      }
    },
    {
      "id": "opensuse-tumbleweed",
      "name": "openSUSE Tumbleweed",
      "family": "linux",
      "summary": {
        "en": "A tested rolling release: always up to date, with a lightweight Xfce live desktop you can try before installing.",
        "fr": "Une rolling release testée : toujours à jour, avec un bureau Xfce léger en session live à essayer avant d'installer.",
        "es": "Una rolling release probada: siempre al día, con un escritorio Xfce ligero en sesión live para probar antes de instalar.",
        "it": "Una rolling release testata: sempre aggiornata, con un desktop Xfce leggero in sessione live da provare prima di installare."
      },
      "tags": [
        "rolling",
        "desktop",
        "light"
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
        "url": "https://download.opensuse.org/ports/aarch64/tumbleweed/iso/openSUSE-Tumbleweed-XFCE-Live-aarch64-Current.iso",
        "versionPattern": "Snapshot([0-9]+)",
        "checksum": {
          "url": "{url}.sha256",
          "algorithm": "sha256"
        }
      },
      "snapshot": {
        "version": "20261117",
        "url": "https://downloadcontent.opensuse.org/ports/aarch64/tumbleweed/iso/openSUSE-Tumbleweed-XFCE-Live-aarch64-Snapshot20261117-Media.iso",
        "algorithm": "sha256",
        "digest": "3542cd8e4b1cfb134666bda26bef9931dcc78cb5e381575f312d24fe93b2f5e3",
        "bytes": 1423998976,
        "date": "2026-11-18"
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
      }
    }
  ]
}
"""#
}
