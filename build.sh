#!/usr/bin/env bash
# Builds the zip CurseForge expects: a single top-level folder named exactly
# like the addon and its .toc file, containing only the files the game loads.
set -euo pipefail

ADDON="SpellCoeffsForever"
VERSION="$(sed -n 's/^## Version: *//p' "${ADDON}.toc" | head -1)"
OUT="dist"

rm -rf "${OUT}"
mkdir -p "${OUT}/${ADDON}"

cp "${ADDON}.toc" "${ADDON}_Vanilla.toc" Compat.lua Data.lua Core.lua Options.lua \
   README.md LICENSE "${OUT}/${ADDON}/"

(cd "${OUT}" && zip -qr "${ADDON}-${VERSION}.zip" "${ADDON}")
rm -rf "${OUT:?}/${ADDON}"

echo "built ${OUT}/${ADDON}-${VERSION}.zip"
unzip -l "${OUT}/${ADDON}-${VERSION}.zip"
