# DET-001 — Detection Validation

## Objective

Validate that the CloudGuard Wazuh detection correctly identifies an AWS
`CreateAccessKey` event generated through an assumed-role session.

## Test Event

The following AWS-shaped event was supplied to Wazuh Logtest:

```json
{
  "integration": "aws",
  "aws": {
    "source": "cloudtrail",
    "eventSource": "iam.amazonaws.com",
    "eventName": "CreateAccessKey",
    "userIdentity": {
      "type": "AssumedRole"
    }
  }
}

## Post-Cleanup Validation

The experimental development rules were removed from the live Wazuh
configuration and the Wazuh Manager was restarted.

The detection was then retested with the same AWS-shaped event.

The final result remained:

- Rule `100201`
- Level `8`
- MITRE `T1098.001`
- Tactic: Persistence
- Technique: Additional Cloud Credentials

**Post-cleanup validation: PASS**

This confirmed that the final detection depends only on the intended
`100200 → 100201` rule chain.
