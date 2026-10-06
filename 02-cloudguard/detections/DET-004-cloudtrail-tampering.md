# DET-004 — CloudTrail Tampering

**Status:** VALIDATED AT AWS/CLOUDTRAIL LAYER

## Objective

Detect attempts to disable AWS CloudTrail logging.

Disabling or modifying security logging can reduce visibility during an attack and is therefore a high-value cloud security event.

## Detection Logic

The primary event is:

`eventName = StopLogging`

Additional CloudTrail configuration changes that may be investigated include:

- `StartLogging`
- `StopLogging`
- `UpdateTrail`
- `DeleteTrail`
- `PutEventSelectors`
- `PutInsightSelectors`

The primary controlled detection test focused on `StopLogging`.

## AWS Configuration

CloudTrail trail:

`cloudsec-wazuh-trail`

Region:

`eu-north-1`

Before testing, CloudTrail status was confirmed as:

`IsLogging = true`

## Controlled Test

A controlled `StopLogging` API call was performed against the CloudTrail trail to simulate an attempt to disable security monitoring.

The trail was immediately restarted after the test.

CloudTrail status was then verified as:

`IsLogging = true`

## CloudTrail Evidence

CloudTrail Event History confirmed the `StopLogging` event.

Event details:

- Event name: `StopLogging`
- Event source: `cloudtrail.amazonaws.com`
- Event category: `Management`
- Read-only: `false`
- Region: `eu-north-1`
- Trail: `cloudsec-wazuh-trail`
- Event time: `2026-10-06T19:27:41Z`
- Event ID: `72fdbce4-af7e-4f9c-80b1-ba7f5f9c37d4`
- Identity type: `AssumedRole`
- Role: `Arowojebe-AdminRole`
- Session: `Arowojebe-Admin`
- MFA authenticated: `false`
- Source IP: `13.60.3.22`
- User agent: AWS CLI from CloudShell

CloudTrail status confirmed:

- Logging stopped: `19:27:41 UTC`
- Logging restarted: `19:28:06 UTC`
- Logging active after test: `true`

The controlled interruption lasted approximately 25 seconds.

## Wazuh Validation

The CloudTrail `StopLogging` event was confirmed through AWS CloudTrail Event History.

The corresponding event was not located in the Wazuh archive or alert logs during validation.

Therefore, the detection was validated at the AWS/CloudTrail layer rather than claiming successful Wazuh end-to-end alerting.

## Result

**VALIDATED — AWS/CLOUDTRAIL**

The controlled `StopLogging` activity was successfully recorded by CloudTrail and the trail was restored immediately after testing.

## Security Interpretation

An unexpected `StopLogging` event should be treated as high priority because an attacker may attempt to reduce visibility before performing additional actions.

Investigation should determine:

- who stopped logging
- which trail was affected
- whether the action was authorized
- source IP and session
- MFA status
- preceding activity
- activity performed while logging was disabled
- whether logging was restored
- whether additional CloudTrail configuration changes occurred

## MITRE ATT&CK

**T1562.001 — Impair Defenses: Disable or Modify Tools**

Disabling CloudTrail can reduce defensive visibility and may represent an attempt to impair security monitoring.

## Lessons Learned

CloudTrail configuration changes are themselves important security telemetry.

A security engineer should monitor not only the activity occurring inside cloud resources but also changes to the controls responsible for recording that activity.

This exercise demonstrated a controlled CloudTrail tampering scenario and confirmed that AWS CloudTrail recorded the security-relevant event.
