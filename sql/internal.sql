CREATE TABLE requests (
    id              uuid PRIMARY KEY,
    sender          text,
    subject         text NOT NULL,
    body_path       text NOT NULL,
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
    author          text NOT NULL,
    approver        text,
    sensitivity     text NOT NULL DEFAULT 'normal' CHECK (sensitivity IN ('normal', 'sensitive')),
    base_path       text,
    base_sha256     char(64),
    base_bytes      bigint,
    signed_path     text,
    signed_sha256   char(64),
    signed_by       text,
    signer_account  text,
    signature_result text,
    dlp_result      jsonb,
    status          text NOT NULL CHECK (status IN (
                        'draft', 'flattening', 'blocked', 'awaiting_approval',
                        'refused', 'approved', 'awaiting_signature',
                        'signature_rejected', 'sent', 'rejected_by_ext',
                        'released', 'expired')),
    approved_at     timestamptz,
    UNIQUE (request_id, version),
    CHECK (approver IS NULL OR approver <> author)
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
    previous_hash   char(64) NOT NULL,
    event_hash      char(64) NOT NULL
);
