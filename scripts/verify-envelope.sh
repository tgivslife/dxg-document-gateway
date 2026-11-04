#!/usr/bin/env bash
# verify-envelope.sh <dir> <ca.crt> <expected-signer-sha256-fingerprint>
set -euo pipefail
dir=$1; ca=$2; expected=$3

openssl cms -verify -binary -inform DER \
  -in "$dir/envelope.json.p7s" -content "$dir/envelope.json" \
  -CAfile "$ca" -purpose any -signer "$dir/signer.pem" -out /dev/null

actual=$(openssl x509 -in "$dir/signer.pem" -noout -fingerprint -sha256 | cut -d= -f2)
[ "$actual" = "$expected" ] || { echo "unexpected signer" >&2; exit 1; }

want=$(jq -r .payload_sha256 "$dir/envelope.json")
have=$(sha256sum "$dir/payload.cms" | cut -d' ' -f1)
[ "$want" = "$have" ] || { echo "payload hash mismatch" >&2; exit 1; }
