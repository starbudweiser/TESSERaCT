#!/bin/zsh
# Compile TESSERaCT (optimisé, avec QEMU) et l'installe dans ~/Applications/Applications Personnelles.
# Appelé par _tools/build_all.sh. Quitter l'appli (⌘Q) avant : elle refuse de remplacer une copie qui tourne.
set -euo pipefail
root=${0:A:h:h}
export PATH=/opt/homebrew/bin:$PATH
exec "$root/scripts/build.sh" --output "$HOME/Applications/Applications Personnelles/TESSERaCT.app"
