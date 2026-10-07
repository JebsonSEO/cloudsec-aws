# INC-001 — Suspicious Credential Activity

## Incident Type

AWS IAM credential creation through an assumed-role session.

## Severity

High

## Status

Closed — Investigation and response workflow completed.

---

## 1. Incident Summary

CloudGuard detected an AWS IAM `CreateAccessKey` event involving the
`wazuh-detection-test` IAM user.

The API action was performed through an assumed-role session associated
with `Arowojebe-AdminRole`.

The event was investigated using CloudTrail evidence and the CloudGuard
incident-response methodology:

> WHO → WHAT → WHEN → WHERE → HOW → IMPACT → CONTAINMENT →
> REMEDIATION → RECOVERY → VALIDATION

The investigation focused on establishing facts before determining
whether the activity represented unauthorized behavior.

---

## 2. Detection

### Detection ID

DET-001

### Detected Activity

`CreateAccessKey`

### AWS Service

`iam.amazonaws.com`

### Event Type

`AwsApiCall`

### Event Category

`Management`

### Detection Path

AWS CloudTrail → Wazuh → Custom CloudGuard Detection

### MITRE ATT&CK

T1098.001 — Additional Cloud Credentials

---

## 3. Initial Triage

An alert does not automatically represent a confirmed attack.

The first stage of investigation established:

- who performed the API action
- what action was performed
- when it occurred
- where it originated
- how it was authenticated and executed
- what identity/resource was affected

This prevented the investigation from treating `CreateAccessKey`
as automatically malicious.

---

## 4. WHO — Actor Identification

CloudTrail identified the API caller as an assumed-role session.

### Evidence

- Identity type: `AssumedRole`
- Role: `Arowojebe-AdminRole`
- Session: `Arowojebe-Admin`

The role was the acting identity context.

The affected IAM user was:

`wazuh-detection-test`

### Investigation Principle

`userIdentity.type` identifies the type of identity, while the
session issuer identifies the IAM role associated with the assumed
session.

---

## 5. WHAT — Activity Identification

The API action was:

`CreateAccessKey`

The affected resource was the IAM user:

`wazuh-detection-test`

The action resulted in an AWS access key being created for the user.

The resulting credential was recorded as active.

### Important Distinction

`AwsApiCall` describes the CloudTrail event type.

`CreateAccessKey` identifies the actual AWS API action.

CloudTrail provides the authoritative evidence that the API operation
occurred. Wazuh provides the detection and alerting layer.

---

## 6. WHEN — Timeline

### Event Time

`2026-10-02T17:14:29Z`

The timestamp was evaluated as part of the incident timeline.

Additional surrounding events should be reviewed when determining
whether activity was expected or suspicious.

### Investigation Considerations

- activity immediately before the event
- activity immediately after the event
- expected administrative activity
- maintenance or deployment activity
- related API calls from the same identity/session

---

## 7. WHERE — Source Analysis

### Source IP

`105.119.1.61`

### AWS Region

`us-east-1`

### User Agent

Firefox on Ubuntu

The source IP was treated as an investigation signal rather than
proof of compromise.

The investigation should determine whether the address belongs to
an expected network, VPN, proxy, cloud environment, administrator
workstation, or another legitimate access path.

User-Agent information was used as supporting context rather than
strong identity proof because it can be spoofed.

---

## 8. HOW — Authentication and Execution Context

The event was performed through an assumed-role session.

### Observed Context

- Identity type: `AssumedRole`
- Role: `Arowojebe-AdminRole`
- Session: `Arowojebe-Admin`
- User agent: Firefox on Ubuntu
- Source IP: `105.119.1.61`
- MFA authenticated: `false`

The absence of recorded MFA authentication was treated as contextual
evidence and not as proof that the activity was malicious.

---

## 9. Credential Usage Investigation

After identifying the newly created credential, the next investigation
stage was to determine whether it had been used.

The following questions were established as the credential-usage
investigation checklist:

1. When was the key first used?
2. What API actions did it perform?
3. What resources did it access or modify?
4. Where did the usage originate?
5. Did the activity escalate the incident?

This establishes an activity timeline and helps determine whether the
credential resulted in actual unauthorized activity.

---

## 10. Blast Radius Assessment

The investigation compared:

> Authorized permissions vs. actual activity

For example, `s3:GetObject` represents read access to S3 objects and
can create a confidentiality impact if sensitive data is accessed.

The scope of the permission is therefore important.

A narrowly scoped:

`s3:GetObject`

permission on a single bucket presents a different blast radius
from the same permission applied broadly across multiple buckets.

Other permissions such as:

- `s3:PutObject`
- `s3:DeleteObject`

could introduce additional integrity or availability impacts.

---

## 11. Containment

Once unauthorized credential activity is established, the primary
containment action is to disable the suspicious access key.

Containment should stop further unauthorized activity while preserving
the evidence required for investigation.

### Containment Principle

Do not unnecessarily delete identities, logs, or other evidence before
understanding the incident.

The compromised credential can be disabled while CloudTrail evidence
and other investigation data are preserved.

---

## 12. Remediation

Remediation focuses on the root cause rather than only the immediate
credential.

The investigation should examine:

- how the actor obtained the ability to assume the role
- the role trust policy
- the role permissions policy
- excessive privileges
- authentication requirements
- other active credentials
- alternative paths to the same privileged role

### Trust Policy

The trust policy determines who can assume a role.

Unexpected or overly broad principals should be removed and the trust
relationship narrowed.

### Permission Policy

The permission policy determines what an assumed role can do.

Excessive permissions should be removed according to the principle of
least privilege.

### Key Security Principle

> Trust policy controls who can assume the role.
>
> Permission policy controls what the role can do.

Both layers must be evaluated.

---

## 13. Recovery

Recovery verifies that the environment has returned to a known-good
security state.

Validation should include:

- unauthorized access key disabled or revoked
- no continuing activity from the compromised credential
- no additional unauthorized credentials
- IAM permissions reviewed
- role trust policy corrected
- authentication controls reviewed
- CloudTrail logging operational
- monitoring pipeline operational
- DET-001 detection still functional

The affected IAM user should only be deleted when its business or
operational purpose has been evaluated. Lab-only identities can be
removed after required evidence has been preserved.

---

## 14. Final Validation

The incident can be considered ready for closure when:

- the active threat has been contained
- the root cause has been addressed
- unauthorized credentials have been dealt with
- relevant permissions and trust relationships have been reviewed
- monitoring remains operational
- detection capability has been validated
- sufficient evidence has been preserved

### Closure Principle

> Threat contained → root cause remediated → environment recovered →
> security controls validated.

---

## 15. Lessons Learned

### 1. Evidence before conclusions

Jumping to conclusions from an alert is not a reliable security
practice. A Cloud Security Engineer must investigate available
evidence, establish facts, and assess context before determining
whether activity is malicious.

### 2. Security events require appropriate investigation

Even seemingly small credential events can become significant when
privileged identities or sensitive resources are involved.

An alert should not automatically be treated as an attack, but neither
should suspicious activity be dismissed without investigation.

### 3. Identity and access management is foundational

IAM controls who can access cloud resources, what they can do, and
under what conditions.

Poorly governed identities, credentials, permissions, or trust
relationships can create significant cloud security exposure.

---

## 16. Incident Response Methodology

CloudGuard uses the following investigation model for suspicious
credential activity:

```text
Detection
    ↓
Triage
    ↓
WHO
WHAT
WHEN
WHERE
HOW
    ↓
Credential Usage
    ↓
Blast Radius
    ↓
Containment
    ↓
Remediation
    ↓
Recovery
    ↓
Validation
    ↓
Lessons Learned
    ↓
Incident Closure
