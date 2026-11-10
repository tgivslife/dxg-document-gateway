# dxg-document-gateway

The design of the Document Exchange Gateway (DXG), which moves documents between an internet-connected external
network and a classified internal network that never connect to each other:

- **Requests coming in**: an adapter, mail first, leaves each request in an intake folder; the files are screened and
  rebuilt as flattened PDFs in an isolated VM, an operator selects what to send, and signed, encrypted packages cross
  a DMZ to the internal network.
- **Responses going out**: users write and sign a response in the existing composing application, through the
  organisation's PKI service; DXG checks the seal and the signatures, carries the PDF out unchanged, and a release
  officer on the external network chooses the recipient and channel.

Nothing is built yet. The repository holds the design and the small files it refers to, and the security team decides
the architecture before implementation starts.

## Documentation

- [Proposal](document-exchange-proposal.md): the short overview for the security team, with the seven decisions it
  asks for.
- [Technical design](document-exchange-mvp-technical-documentation.md): requirements, flows, components, network,
  threat model, file handling, packages, operations, tests, delivery plan and open items, with appendices for
  settings, interfaces and deployment.
- [Signed PDF passthrough](document-exchange-signed-pdf-passthrough.md): an optional feature that is disabled by
  default.

The technical design links to the files beside it: PDF checks in `checks/`, package scripts in `scripts/`, the
database tables in `sql/`, the envelope schema in `schemas/`, manifest examples in `examples/`, the proof-of-concept
Compose file in `poc/`, and host settings in `deploy/`. Appendix G of the technical design says which of them were
run and which were not.

## Requirements

- OpenSSL 3.5 LTS or later, `jq`, GNU `tar` and GNU coreutils, for the package scripts in `scripts/`
- Python 3 with pikepdf 10.18.0, and qpdf 12.4.2, for the PDF checks in `checks/`
- PostgreSQL 16 or later, for the tables in `sql/`
- Docker with Compose, to validate `poc/docker-compose.yml` (the `dxg/*` images are not built yet)
- mermaid-cli, to render the diagrams in the documents
