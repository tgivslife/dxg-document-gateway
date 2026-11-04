#!/usr/bin/env bash
# open-payload.sh <payload.cms> <recipient.crt> <recipient.key> <ca.crt> <out.tar>
set -euo pipefail
payload=$1; crt=$2; key=$3; ca=$4; out=$5
tmp=$(mktemp -p /dev/shm)
trap 'rm -f "$tmp"' EXIT

openssl cms -decrypt -binary -inform DER -in "$payload" \
  -recip "$crt" -inkey "$key" -out "$tmp"

openssl cms -verify -binary -inform DER -in "$tmp" \
  -CAfile "$ca" -purpose any -out "$out"
