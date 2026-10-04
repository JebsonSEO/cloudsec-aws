# 01 — AWS Secure Cloud Foundations

Hands-on AWS security engineering work focused on building secure infrastructure,
testing security controls, and understanding the impact of cloud misconfigurations.

## What I Built

- VPC network segmentation with public and private subnets
- EC2 network access restrictions
- IAM least-privilege policy design
- S3 public-access breach recreation and remediation
- CloudTrail verification of security-sensitive API activity
- STRIDE threat modeling
- IAM role and STS assumed-role testing
- Credential blast-radius analysis

## Security Approach

The work follows a simple principle:

> Build the control, test the control, break the control safely, then verify the remediation.

## Threat Modeling

The architecture was evaluated using the STRIDE framework, including an
explicitly documented denial-of-service resilience gap.

See:

`threat-modeling/STRIDE-threat-model.md`

## Next Phase

The foundation established here becomes the environment for:

**02 — CloudGuard: AWS Cloud Identity Detection & Incident Response**

CloudGuard extends the project from preventive security into cloud monitoring,
detection engineering, threat hunting, investigation, and incident response.
