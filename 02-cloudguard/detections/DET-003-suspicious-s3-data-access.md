# DET-003 — Suspicious S3 Data Access

**Status:** VALIDATED AT AWS/CLOUDTRAIL LAYER

## Objective

Detect and investigate access to sensitive S3 objects using AWS CloudTrail Data Events.

The purpose of this detection is to provide object-level visibility into S3 data access that is not captured by management events alone.

## Detection Logic

The detection focuses on:

- `eventName = GetObject`
- `eventCategory = Data`
- `readOnly = true`
- `resources.type = AWS::S3::Object`

A `GetObject` event is not automatically malicious. Investigation should determine whether the access was authorized and whether the object contains sensitive information.

## AWS Configuration

CloudTrail trail:

`cloudsec-wazuh-trail`

S3 Data Event selector:

- `eventCategory = Data`
- `readOnly = true`
- `resources.type = AWS::S3::Object`
- S3 resource prefix:
  `arn:aws:s3:::cloudguard-s3-lab-911635674505/`

Test bucket:

`cloudguard-s3-lab-911635674505`

Test object:

`sensitive-data/customer-transactions.csv`

## Controlled Test

A controlled `GetObject` request was performed against the test object.

The object was successfully retrieved from S3 with HTTP status `200`.

## CloudTrail Evidence

CloudTrail recorded the following event:

- Event name: `GetObject`
- Event source: `s3.amazonaws.com`
- Region: `eu-north-1`
- Event category: `Data`
- Read-only: `true`
- Management event: `false`
- Object size: `151` bytes
- HTTP status: `200`
- Event time: `2026-10-06T12:03:22Z`
- Event ID: `92fac8fb-3671-4508-8d1f-aefe97b02364`

The event was confirmed inside the CloudTrail log file delivered to the S3 CloudTrail bucket.

## Wazuh Validation

The CloudTrail log file containing the event was confirmed as processed by the Wazuh AWS-S3 module.

However, the individual `GetObject` event could not be located in the Wazuh archive or alert logs.

The installed Wazuh CloudTrail handler was also inspected and no explicit filter excluding CloudTrail Data Events was identified.

Therefore, the AWS detection was validated independently of Wazuh's alerting pipeline.

## Result

**VALIDATED — AWS/CLOUDTRAIL**

The CloudTrail Data Event configuration successfully captured the controlled S3 object access.

Wazuh ingestion of the specific Data Event could not be validated and is documented as a separate ingestion limitation.

## Security Interpretation

A single `GetObject` event does not prove malicious activity.

During an investigation, the following should be examined:

- identity and assumed role
- source IP
- accessed object
- access time
- repeated object access
- preceding reconnaissance
- authorization status
- subsequent data access or exfiltration activity

## MITRE ATT&CK

Potential technique:

**T1530 — Data from Cloud Storage**

The technique becomes relevant when cloud storage data is accessed by an unauthorized actor.

## Lessons Learned

CloudTrail Data Events provide object-level visibility that management events do not provide.

This exercise demonstrated the difference between:

1. generating security telemetry,
2. collecting the telemetry,
3. ingesting it into a security monitoring platform, and
4. generating a detection.

CloudTrail successfully provided the required AWS security evidence even though the corresponding event was not observable in the Wazuh analysis pipeline.
