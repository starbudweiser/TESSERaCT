#!/bin/zsh
# Publie une version de TESSERaCT comme les autres applis : build de diffusion (Developer ID, runtime renforcé, QEMU inclus),
# notarisation par _tools/notarize_app.sh, TESSERaCT.zip et son .sha256 dans build/release/dist.
# Usage : scripts/release.sh <X.Y.Z> [--publish]   (--publish : crée aussi la release GitHub v<X.Y.Z>). À lancer sur demande seulement.
# L'app est déjà signée avec les droits propres de chaque binaire (QEMU, rendu, app) : notarize_app.sh ne la re-signe pas (NOTARIZE_ONLY=1).
set -euo pipefail
root=${0:A:h:h}
version=${1:?Usage: scripts/release.sh <X.Y.Z> [--publish]}
publish=false; [[ ${2:-} == --publish ]] && publish=true
export PATH=/opt/homebrew/bin:$PATH
kc=$HOME/Library/Keychains/skyrim-signing.keychain-db
security unlock-keychain -p "$(cat "$HOME/.skyrim-signing/keychain.pw")" "$kc"
export TESSERACT_SIGN_IDENTITY=$(security find-identity -v -p codesigning "$kc" | grep 'Developer ID Application' | awk '{print $2}' | head -1)
[[ -n $TESSERACT_SIGN_IDENTITY ]] || { print -u2 "Pas de certificat Developer ID dans $kc"; exit 1; }
dist=$root/build/release/dist
rm -rf "$dist"; mkdir -p "$dist"
"$root/scripts/build-release.sh" --version "$version" --no-image --output "$root/build/release"
NOTARIZE_ONLY=1 DIST="$dist" /Volumes/SKYRIM/TOOLS/MAC/_tools/notarize_app.sh "$root/build/release/TESSERaCT.app"
(cd "$dist" && shasum -a 256 TESSERaCT.zip > TESSERaCT.zip.sha256)
if $publish; then
    gh release create "v$version" "$dist/TESSERaCT.zip" "$dist/TESSERaCT.zip.sha256" --target main --title "TESSERaCT $version" --notes "TESSERaCT $version"
fi
print "Prêt : $dist/TESSERaCT.zip"
