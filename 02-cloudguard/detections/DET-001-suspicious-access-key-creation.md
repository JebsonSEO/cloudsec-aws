# DET-001 — Suspicious AWS Access-Key Creation

## Objective

Detect AWS IAM access-key creation and increase the alert severity when the
credential is created by an assumed-role session.

The detection is designed to identify potentially suspicious credential
persistence while recognizing that access-key creation can also be legitimate.

## Data Source

- AWS CloudTrail
- Amazon S3
- Wazuh AWS-S3 integration
- Wazuh AWS CloudTrail rules

## Detection Logic

### Rule 100200 — Base Detection

Triggers when:

```text
AWS eventName = CreateAccessKey
