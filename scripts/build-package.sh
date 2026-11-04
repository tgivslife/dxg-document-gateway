#!/usr/bin/env bash
# build-package.sh <inner.tar> <envelope-template.json> <sign.crt> <sign.key> <recipient.crt> <out-dir>
set -euo pipefail
inner=$1; template=$2; sign_crt=$3; sign_key=$4; recipient=$5; out=$6
mkdir -p "$out"

openssl cms -sign -binary -nodetach -md sha256 \
  -signer "$sign_crt" -inkey "$sign_key" \
  -in "$inner" -outform DER -out "$out/inner.p7s"

openssl cms -encrypt -binary -aes-256-gcm \
  -in "$out/inner.p7s" -outform DER -out "$out/payload.cms" "$recipient"

hash=$(sha256sum "$out/payload.cms" | cut -d' ' -f1)
bytes=$(stat -c %s "$out/payload.cms")
jq --arg hash "$hash" --argjson bytes "$bytes" \
  '. + {payload_sha256: $hash, payload_bytes: $bytes}' \
  "$template" > "$out/envelope.json"

openssl cms -sign -binary -md sha256 \
  -signer "$sign_crt" -inkey "$sign_key" \
  -in "$out/envelope.json" -outform DER -out "$out/envelope.json.p7s"

package_id=$(jq -r .package_id "$out/envelope.json")
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='1970-01-01Z' \
  -C "$out" -cf "$out/$package_id.tar" envelope.json envelope.json.p7s payload.cms
rm -f "$out/inner.p7s"
