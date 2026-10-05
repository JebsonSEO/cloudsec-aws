# DET-002 — IAM Reconnaissance Activity

## Objective

Detect AWS IAM discovery activity that may indicate an attempt to understand available identities, roles, and permissions.

## Detection Logic

CloudGuard monitors CloudTrail events associated with IAM reconnaissance:

- `GetCallerIdentity`
- `ListUsers`
- `ListRoles`
- `GetPolicy`
- `GetRole`

These events are individually legitimate AWS API operations. The security value comes from examining them in context and identifying repeated or clustered discovery activity.

## Detection Flow

```text
AWS CloudTrail
      ↓
S3 CloudTrail Logs
      ↓
Wazuh AWS-S3 Integration
      ↓
IAM Discovery Events
      ↓
CloudGuard Detection
      ↓
Analyst Investigation
