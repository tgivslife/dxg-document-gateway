base64 -w0 input.pdf > input.b64
base64 -w0 dxg-policy.xml > policy.b64
jq -n --rawfile doc input.b64 --rawfile policy policy.b64 '{
  signedDocument: { bytes: $doc, name: "input.pdf" },
  policy: { bytes: $policy, name: "dxg-policy.xml" }
}' > validate-request.json
