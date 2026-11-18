# Traduction de TESSERaCT (FR, EN, ES, IT)

Langue de l'interface = langue préférée du système ; hors des 4 langues, anglais (CFBundleDevelopmentRegion = en).
Les textes sont dans `Localizations/<langue>.lproj/Localizable.strings` (fusion des fragments `_parts/<groupe>/<langue>.strings`
par `scripts/merge-localizations.py`). La clé est le texte anglais d'origine, mêmes clés dans les 4 langues (en = identité).

## Dans le code (App/)
- `Text("…")`, `Button("…")`, `Label("…", systemImage:)`, `Toggle`, `Section`, `Picker`, `TextField` (titre), `.help("…")`,
  `.navigationTitle("…")`, `LabeledContent("…")`, `Menu("…")`, `Link`… : un littéral est déjà une clé SwiftUI, ne rien changer.
- Tout texte visible qui passe par un `String` (propriété calculée, message d'erreur, titre d'alerte `NSAlert`, titre de menu
  `NSMenuItem`, titre de fenêtre, état « Running », etc.) : `String(localized: "…")` (bundle principal, pas d'autre paramètre).
- `Text(uneVariableString)` n'est PAS traduit : localiser la variable à sa source, ou passer un littéral.
- Phrase construite par morceaux ou par ternaire (`"Sound will be \(on ? "on" : "off") the next time…"`) : la remplacer par
  des phrases entières (un ternaire entre deux `String(localized:)` complets) pour que chaque langue ait sa grammaire.
- Ne pas traduire : noms de symboles SF, identifiants, clés UserDefaults, extensions, commandes shell, sorties de `tctl`/MCP
  et réponses de `ControlService` destinées aux agents (restent en anglais), journaux, `print`, noms propres (TESSERaCT,
  macOS, Windows, Linux, QEMU, tctl, ssh, SSH, GPU, USB, ISO, IPSW, TPM, DirectX…).

## Clés
- Une interpolation devient un spécificateur : Int → `%lld`, Double → `%lf`, String ou autre → `%@`
  (`"\(count) machines"` → clé `"%lld machines"`). Si le type est douteux, convertir au site d'appel (`\(String(x))`) pour avoir `%@`.
- Dans les traductions, utiliser les positions (`%1$@`, `%2$lld`) dès qu'il y a 2 spécificateurs ou plus.
- `%` littéral = `%%`. Guillemets droits échappés `\"`, retour ligne `\n`, antislash `\\`. Les guillemets typographiques “ ” du
  texte source sont conservés dans la clé ; en français les rendre « … » avec espaces insécables (U+00A0).
- Français : espace insécable (U+00A0) avant `: ; ? !`, apostrophe courbe non requise (’ ou ' au choix, rester cohérent : '),
  verbes d'action à l'infinitif dans les boutons et menus (« Démarrer », « Supprimer… »), « vous/votre » dans les phrases.
- Format d'un fragment : `"clé" = "valeur";` une par ligne, `/* fichier:ligne */` facultatif. Pas de clé en double dans un fragment.
  Fichiers `en.strings`, `fr.strings`, `es.strings`, `it.strings` ayant exactement les mêmes clés.

## Glossaire (à respecter strictement, pour que tous les écrans parlent pareil)
| EN | FR | ES | IT |
|---|---|---|---|
| virtual machine | machine virtuelle | máquina virtual | macchina virtuale |
| guest (system inside the VM) | invité | invitado | ospite |
| guest tools | outils invités | herramientas del invitado | strumenti ospite |
| this Mac (the host) | ce Mac | este Mac | questo Mac |
| snapshot | instantané | instantánea | istantanea |
| template | modèle | plantilla | modello |
| Seamless Mode | Mode intégré | Modo integrado | Modalità integrata |
| shared folder | dossier partagé | carpeta compartida | cartella condivisa |
| disc image / disk image | image de disque (ISO : image disque) / image disque | imagen de disco | immagine disco |
| Start / Resume | Démarrer / Reprendre | Iniciar / Reanudar | Avvia / Riprendi |
| Suspend / Pause | Suspendre / Mettre en pause | Suspender / Pausar | Sospendi / Pausa |
| Shut Down / Restart / Force Stop | Éteindre / Redémarrer / Forcer l'arrêt | Apagar / Reiniciar / Forzar detención | Spegni / Riavvia / Forza arresto |
| Revert | Revenir à cet état | Volver a este estado | Ripristina questo stato |
| Settings | Réglages | Ajustes | Impostazioni |
| processors / memory | processeurs / mémoire | procesadores / memoria | processori / memoria |
| port forwarding | redirection de ports | reenvío de puertos | inoltro delle porte |
| Move to Trash | Placer dans la corbeille | Mover a la papelera | Sposta nel Cestino |
| Delete / Cancel / Done | Supprimer / Annuler / Terminé | Eliminar / Cancelar / Hecho | Elimina / Annulla / Fine |
| Quit / Copy / Choose… | Quitter / Copier / Choisir… | Salir / Copiar / Elegir… | Esci / Copia / Scegli… |
| Setup Scripts | scripts de configuration | scripts de configuración | script di configurazione |
| Bridged / Shared (NAT) | Pont / Partagé (NAT) | Puente / Compartida (NAT) | Bridge / Condivisa (NAT) |
