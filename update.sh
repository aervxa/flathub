#!/usr/bin/bash
set -e

TAG="${1:?Usage: $0 <tag/branch>}"

# tmp dir
cd "$(dirname "$0")" # Enter direcotry of script
rm -rf tmp
mkdir tmp
cd tmp

# clone repo and add builder tools
git -c advice.detachedHead=false clone https://github.com/aervxa/lepse --branch "$TAG"
cd lepse
git submodule add https://github.com/flatpak/flatpak-builder-tools.git

# setup a temp python
python -m venv .venv
source .venv/bin/activate

# Install python deps
pip install flatpak-builder-tools/node aiohttp tomlkit

# Generate node and cargo deps
flatpak-node-generator --no-requests-cache -o ../../node-sources.json pnpm pnpm-lock.yaml --pnpm-store-version v11
python flatpak-builder-tools/cargo/flatpak-cargo-generator.py -o ../../cargo-sources.json apps/lachesis/src-tauri/Cargo.lock

# Exit and remove tmp dir
cd ../..
COMMIT=$(git -C tmp/lepse rev-parse HEAD)
rm -rf tmp

# Update the manifest (this entirely relies on the fact of there being just one tag and commit on the file)
sed -i "s/tag:.*/tag: $TAG/" app.lepse.Lepse.yml
sed -i "s/commit:.*/commit: $COMMIT/" app.lepse.Lepse.yml
