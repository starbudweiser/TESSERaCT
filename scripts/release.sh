#!/bin/zsh
# Compile TESSERaCT en version de diffusion (Developer ID, runtime renforcé), l'emballe en .dmg, le fait notariser
# par Apple et agrafe le ticket. Usage : scripts/release.sh <X.Y.Z>
# Prérequis : trousseau dédié skyrim-signing (Developer ID) et profil notarytool « Applications ».
set -euo pipefail
root=${0:A:h:h}
version=${1:?Usage: scripts/release.sh <X.Y.Z>}
export PATH=/opt/homebrew/bin:$PATH
kc=$HOME/Library/Keychains/skyrim-signing.keychain-db
security unlock-keychain -p "$(cat "$HOME/.skyrim-signing/keychain.pw")" "$kc"
export TESSERACT_SIGN_IDENTITY=$(security find-identity -v -p codesigning "$kc" | grep 'Developer ID Application' | awk '{print $2}' | head -1)
[[ -n $TESSERACT_SIGN_IDENTITY ]] || { print -u2 "Pas de certificat Developer ID dans $kc"; exit 1; }
"$root/scripts/build-release.sh" --version "$version" --output "$root/build/release"
dmg=$root/build/release/TESSERaCT-$version.dmg
xcrun notarytool submit "$dmg" --keychain-profile "${NOTARY_PROFILE:-Applications}" --wait
xcrun stapler staple "$dmg"
spctl --assess --type open --context context:primary-signature -v "$dmg"
print "Prêt : $dmg"
