CREATE TABLE requests (
    id              uuid PRIMARY KEY,
    sender          text,
    subject         text,
    body_path       text,
    status          text NOT NULL CHECK (status IN ('open', 'closed')),
    received_at     timestamptz NOT NULL
);

CREATE TABLE documents (
    id              uuid PRIMARY KEY,
    request_id      uuid NOT NULL REFERENCES requests(id),
    display_name    text NOT NULL,
    path            text NOT NULL,
    sha256          char(64) NOT NULL,
    source_sha256   char(64) NOT NULL,
    signature_state text NOT NULL CHECK (signature_state IN ('none', 'passed', 'review_accepted')),
    signature_info  jsonb,
    report_path     text,
    signable        boolean NOT NULL DEFAULT false,
    original_path   text,
    original_sha256 char(64)
);

CREATE TABLE responses (
    id              uuid PRIMARY KEY,
    request_id      uuid NOT NULL REFERENCES requests(id),
    version         integer NOT NULL,
    kind            text NOT NULL DEFAULT 'signed' CHECK (kind IN ('signed', 'countersigned')),
    source_document_id uuid REFERENCES documents(id),
    source_application text NOT NULL,
    source_reference text NOT NULL,
    sensitivity     text NOT NULL DEFAULT 'normal' CHECK (sensitivity IN ('normal', 'sensitive')),
    signed_path     text NOT NULL,
    signed_sha256   char(64) NOT NULL,
    signed_bytes    bigint NOT NULL,
    signatures      jsonb,
    signature_result text,
    dlp_result      jsonb,
    reject_reason   text CHECK (reject_reason IN (
                        'drop', 'schema', 'request_state', 'size', 'signature',
                        'pdf_policy', 'dlp', 'rejected_by_ext')),
    status          text NOT NULL CHECK (status IN (
                        'received', 'checking', 'rejected', 'sent',
                        'released', 'expired')),
    received_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (request_id, version),
    UNIQUE (source_application, source_reference)
);

CREATE TABLE packages (
    id              uuid PRIMARY KEY,
    request_id      uuid,
    direction       text NOT NULL CHECK (direction IN ('ext_to_int', 'int_to_ext')),
    type            text NOT NULL CHECK (type IN ('import', 'response', 'ack', 'status')),
    seq             bigint NOT NULL,
    state           text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (direction, seq)
);

CREATE TABLE audit_events (
    id              bigserial PRIMARY KEY,
    occurred_at     timestamptz NOT NULL DEFAULT now(),
    actor           text NOT NULL,
    action          text NOT NULL,
    request_id      uuid,
    subject_id      uuid,
    details         jsonb NOT NULL DEFAULT '{}',
    previous_hash   char(64) NOT NULL UNIQUE,
    event_hash      char(64) NOT NULL
);
