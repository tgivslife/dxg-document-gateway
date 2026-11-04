#!/usr/bin/env python3
"""Check a PDF without changing it.

Usage: pdf_policy.py output|signed <path> [max_pages]
Exit 0: passed. Exit 1: policy failed.
Exit 2: signed mode only, the file cannot take another signature.
"""
import subprocess
import sys

import pikepdf

ACTIVE = {
    "/JavaScript", "/JS", "/OpenAction", "/AA", "/Launch", "/EmbeddedFile",
    "/EmbeddedFiles", "/Filespec", "/URI", "/SubmitForm", "/ImportData",
    "/GoToR", "/GoToE", "/RichMedia", "/XFA",
}
OUTPUT_ONLY = {"/AcroForm", "/Annots"}


def fail(reason: str, code: int = 1) -> None:
    print(f"policy_failed: {reason}", file=sys.stderr)
    raise SystemExit(code)


def walk(obj, forbidden: set) -> None:
    """Check one object, including direct objects nested inside it."""
    if isinstance(obj, pikepdf.Stream):
        obj = obj.stream_dict
    if isinstance(obj, pikepdf.Dictionary):
        children = []
        for key, value in obj.items():
            if key in forbidden:
                fail(f"forbidden_key {key}")
            children.append(value)
    elif isinstance(obj, pikepdf.Array):
        children = list(obj)
    else:
        return
    for child in children:
        if isinstance(child, pikepdf.Name) and str(child) in forbidden:
            fail(f"forbidden_value {child}")
        if isinstance(child, (pikepdf.Dictionary, pikepdf.Array)) and not child.is_indirect:
            walk(child, forbidden)


def field_type(field):
    while field is not None:
        if "/FT" in field:
            return str(field["/FT"])
        field = field.get("/Parent")
    return None


def is_locked(pdf) -> bool:
    perms = pdf.Root.get("/Perms")
    if perms is not None and "/DocMDP" in perms:
        for ref in perms["/DocMDP"].get("/Reference", []):
            params = ref.get("/TransformParams")
            if params is not None and int(params.get("/P", 2)) == 1:
                return True
    for obj in pdf.objects:
        if isinstance(obj, pikepdf.Dictionary) and "/Lock" in obj:
            if int(obj["/Lock"].get("/P", 2)) == 1:
                return True
    return False


def check_signed(pdf) -> None:
    for page in pdf.pages:
        for annot in page.get("/Annots", []):
            if str(annot.get("/Subtype")) != "/Widget":
                fail("annotation_type")
            if field_type(annot) != "/Sig":
                fail("non_signature_field")
    form = pdf.Root.get("/AcroForm")
    if form is None or len(form.get("/Fields", [])) == 0:
        fail("no_signature_field")
    for field in form["/Fields"]:
        if field_type(field) != "/Sig":
            fail("non_signature_field")
    if is_locked(pdf):
        fail("no_further_signatures", 2)


def main(mode: str, path: str, max_pages: int) -> None:
    check = subprocess.run(
        ["qpdf", "--check", path], capture_output=True, text=True, timeout=120
    )
    if check.returncode != 0:
        fail("qpdf_check")

    forbidden = ACTIVE | OUTPUT_ONLY if mode == "output" else ACTIVE
    try:
        with pikepdf.open(path) as pdf:
            if pdf.is_encrypted:
                fail("encrypted")
            if len(pdf.pages) == 0 or len(pdf.pages) > max_pages:
                fail("page_count")
            for obj in pdf.objects:
                walk(obj, forbidden)
            walk(pdf.Root, forbidden)
            if mode == "signed":
                check_signed(pdf)
    except pikepdf.PdfError:
        fail("parse_error")


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in ("output", "signed"):
        print(__doc__, file=sys.stderr)
        raise SystemExit(1)
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 500)
