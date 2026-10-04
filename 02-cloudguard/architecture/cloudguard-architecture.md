# CloudGuard — AWS Cloud Identity Detection & Incident Response

## Purpose

CloudGuard is a hands-on AWS cloud security detection and incident response
environment built around AWS CloudTrail and Wazuh.

The project extends the preventive security controls developed in
`01-secure-cloud-foundations` into continuous visibility, detection,
investigation, and response.

## Security Pipeline

```text
AWS IAM / AWS API Activity
          |
          v
     AWS CloudTrail
          |
          v
     Amazon S3
          |
          v
   Wazuh AWS-S3 Integration
          |
          v
    Wazuh Analysis Engine
          |
          v
    Custom Detection Rules
          |
          v
 Threat Hunting / Investigation
          |
          v
 Incident Response
