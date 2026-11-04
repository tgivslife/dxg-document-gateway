#!/usr/bin/env python3
"""Exit 0 if a signed PDF only adds signatures to its base file, otherwise exit 1.

Usage: signature_append_check.py <base> <signed> <base_sha256> <max_append_bytes>
"""
import hashlib
import sys

import pikepdf


def fail(reason: str) -> None:
    print(f"append_failed: {reason}", file=sys.stderr)
    raise SystemExit(1)


def summarize(path: str):
    """Return the signature count and a digest of each page's content."""
    with pikepdf.open(path) as pdf:
        signatures = sum(
            1 for obj in pdf.objects
            if isinstance(obj, pikepdf.Dictionary) and "/ByteRange" in obj
            and obj.get("/Type") != pikepdf.Name.DocTimeStamp
        )
        pages = []
        for page in pdf.pages:
            contents = page.get("/Contents")
            parts = contents if isinstance(contents, pikepdf.Array) else [contents]
            digest = hashlib.sha256()
            for part in parts:
                if part is not None:
                    digest.update(part.read_bytes())
            pages.append(digest.hexdigest())
    return signatures, pages


def main(base_path: str, signed_path: str, expected_sha256: str, max_append: int) -> None:
    with open(base_path, "rb") as f:
        base = f.read()
    if hashlib.sha256(base).hexdigest() != expected_sha256:
        fail("base_hash")

    with open(signed_path, "rb") as f:
        new = f.read()
    if len(new) <= len(base) or new[: len(base)] != base:
        fail("not_append_only")
    if len(new) - len(base) > max_append:
        fail("append_too_large")

    try:
        old_signatures, old_pages = summarize(base_path)
        new_signatures, new_pages = summarize(signed_path)
    except pikepdf.PdfError:
        fail("parse_error")
    if new_signatures <= old_signatures:
        fail("no_new_signature")
    if new_pages != old_pages:
        fail("page_content_changed")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]))
