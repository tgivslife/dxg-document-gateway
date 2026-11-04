CREATE TABLE requests (
    id              uuid PRIMARY KEY,
    source_adapter  text NOT NULL,
    source_reference text NOT NULL,
    message_id      text,
    sender          text,
    subject         text,
    drop_sha256     char(64) NOT NULL,
    evidence_path   text NOT NULL,
    status          text NOT NULL CHECK (status IN (
                        'received', 'screening', 'awaiting_selection',
                        'processing', 'awaiting_review', 'queued_for_b',
                        'delivered_to_b', 'response_ready', 'closed',
                        'rejected', 'failed')),
    received_at     timestamptz NOT NULL,
    UNIQUE (source_adapter, source_reference)
);

CREATE TABLE items (
    id              uuid PRIMARY KEY,
    request_id      uuid NOT NULL REFERENCES requests(id),
    parent_item_id  uuid REFERENCES items(id),
    display_name    text NOT NULL,
    detected_type   text,
    size_bytes      bigint NOT NULL,
    source_sha256   char(64) NOT NULL,
    source_path     text NOT NULL,
    output_sha256   char(64),
    output_path     text,
    is_signed       boolean NOT NULL DEFAULT false,
    passthrough     boolean NOT NULL DEFAULT false,
    status          text NOT NULL CHECK (status IN (
                        'screened', 'rejected', 'selected', 'not_selected',
                        'validating', 'awaiting_review', 'converting',
                        'ready', 'failed')),
    reject_reason   text,
    selected_by     text
);

CREATE TABLE signature_validations (
    id              uuid PRIMARY KEY,
    item_id         uuid NOT NULL REFERENCES items(id),
    validated_at    timestamptz NOT NULL,
    worst_indication text NOT NULL CHECK (worst_indication IN (
                        'TOTAL_PASSED', 'INDETERMINATE', 'TOTAL_FAILED')),
    sub_indication  text,
    signatures_count integer NOT NULL,
    signed_by       text,
    signature_level text,
    signing_time    timestamptz,
    scope_full      boolean NOT NULL,
    dss_version     text NOT NULL,
    policy_sha256   char(64) NOT NULL,
    report_path     text NOT NULL,
    review_decision text CHECK (review_decision IN ('accepted', 'refused')),
    reviewed_by     text,
    review_reason   text
);

CREATE TABLE packages (
    id              uuid PRIMARY KEY,
    request_id      uuid REFERENCES requests(id),
    direction       text NOT NULL CHECK (direction IN ('ext_to_int', 'int_to_ext')),
    type            text NOT NULL CHECK (type IN ('import', 'response', 'ack', 'status')),
    seq             bigint NOT NULL,
    payload_sha256  char(64),
    state           text NOT NULL CHECK (state IN (
                        'created', 'uploaded', 'acked', 'received',
                        'accepted', 'rejected')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (direction, seq)
);

CREATE TABLE responses (
    id              uuid PRIMARY KEY,
    request_id      uuid NOT NULL REFERENCES requests(id),
    package_id      uuid NOT NULL REFERENCES packages(id),
    version         integer NOT NULL,
    kind            text NOT NULL DEFAULT 'signed' CHECK (kind IN ('signed', 'countersigned')),
    sensitivity     text NOT NULL CHECK (sensitivity IN ('normal', 'sensitive')),
    payload_path    text,
    signature_result text,
    status          text NOT NULL CHECK (status IN (
                        'queued', 'pending', 'second_approval', 'releasing',
                        'delivered', 'manual_released', 'failed', 'expired',
                        'superseded')),
    expires_at      timestamptz NOT NULL,
    UNIQUE (request_id, version)
);

CREATE TABLE releases (
    id              uuid PRIMARY KEY,
    response_id     uuid NOT NULL REFERENCES responses(id),
    channel         text NOT NULL,
    recipient       text NOT NULL,
    reason          text,
    created_by      text NOT NULL,
    approved_by     text,
    file_sha256     char(64),
    external_ref    text,
    released_at     timestamptz,
    delivery_result jsonb,
    CHECK (approved_by IS NULL OR approved_by <> created_by)
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
