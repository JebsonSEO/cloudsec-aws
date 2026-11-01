# AWS Secure Infrastructure Foundations

Hands-on lab work covering network segmentation, least privilege IAM design, and a
recreated S3 misconfiguration breach. Built, broken, and fixed personally in a live
AWS account.

## 1. Network Architecture: VPC Segmentation

I designed and built a VPC with separate public and private subnets, so that a
compromised web server cannot reach the database directly. The database is protected
by network design, not just by a password.

```mermaid
graph TD
    Internet[Internet] --> IGW[Internet Gateway]
    IGW --> RT[Route Table: 0.0.0.0/0 to IGW]
    RT --> PubSub[Public Subnet 10.0.1.0/24]
    PubSub --> EC2[EC2 Instance, t3.micro, Ubuntu]
    PrivSub[Private Subnet 10.0.2.0/24, no internet route]

    style PrivSub fill:#f9f9f9,stroke:#c0392b,stroke-width:2px
    style PubSub fill:#f9f9f9,stroke:#2980b9,stroke-width:2px
```

**Decisions made:**
- VPC CIDR set to `10.0.0.0/16`, with subnets sliced into `/24`s for a clear split
  between public and private
- Only the public subnet is attached to the internet routing table. The private
  subnet is left on the VPC's default route table, which has no path to the internet
- The Security Group on the EC2 instance allows SSH only from one known IP address,
  never from anywhere on the internet
- Login to the server uses a key pair, not a password

## 2. IAM: Least Privilege Policy Design

Instead of leaving broad admin access attached for ongoing work, I wrote a policy
scoped to exactly what was needed.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::jebsonseo-practice-bucket-2026"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::jebsonseo-practice-bucket-2026/*"
    }
  ]
}
```

This grants read only access to S3. No write, no delete, no ability to change bucket
permissions. It is a working example of least privilege, not just a definition of it.

## 3. Lab: Recreating the S3 Public Bucket Breach

One of the most common real world cloud breaches is a misconfigured S3 bucket left
open to the public. I recreated that exact failure on purpose, in a controlled way,
to understand both how it happens and how to fix it.

### What I did
1. Created a bucket with AWS's default protection turned on, Block Public Access
2. Confirmed the uploaded file returned a 403 Access Denied when I tried to open its
   public URL
3. Turned off Block Public Access and attached a bucket policy allowing access from
   anyone, the same misconfiguration behind real world breaches
4. Confirmed the file was now publicly reachable
5. Reversed both changes immediately. Re-enabled Block Public Access, deleted the
   open policy, and confirmed the file went back to returning Access Denied

### Why the breach requires two failures, not one
A bucket only becomes public if two separate protections fail at the same time.
Block Public Access has to be turned off, and the bucket policy has to explicitly
allow public access. Either protection alone would have stopped it. This is why
Block Public Access exists as an override sitting above the policy itself. It blocks
public access even if the policy is already misconfigured to allow it, unless someone
deliberately disables it.

### Checked in CloudTrail
The exact API call that changed the bucket policy, PutBucketPolicy, is recorded in
CloudTrail with the IAM identity that made the change, the time it happened, and the
source IP address. Every configuration change in this account can be traced back to a
specific person. Nothing happens anonymously.

## Tools and Services Used
AWS VPC, EC2, S3, IAM, CloudTrail, CloudWatch

## Author
Sheriffdeen, JebsonSEO. Building toward Cloud Security Engineering.

## 4. Terraform: Secure AWS Infrastructure Automation

I extended the project by provisioning and hardening AWS infrastructure with
Terraform. The goal was to make infrastructure changes reproducible, reviewable,
and easier to validate against security best practices.

### Infrastructure and security controls

- **Network segmentation:** Separate public and private subnets, with internet
  routing configured for the public subnet.
- **Security groups:** No inbound rules on the lab instance's security group;
  outbound traffic is restricted to HTTPS.
- **IAM:** An EC2 instance role with the Amazon SSM Managed Instance Core policy,
  allowing management through AWS Systems Manager Session Manager.
- **EC2 hardening:** IMDSv2 is required, the root EBS volume is encrypted, and
  detailed CloudWatch monitoring is enabled.
- **VPC Flow Logs:** VPC traffic logging is enabled and sent to CloudWatch Logs.
- **Log encryption:** A customer-managed AWS KMS key encrypts the Flow Logs
  log group, with automatic key rotation enabled.
- **Infrastructure as Code:** Terraform manages the infrastructure configuration,
  while Git tracks reviewed changes.

### Security validation with Checkov

I scanned the Terraform configuration using Checkov 3.3.28.

| Result | Checks |
|---|---:|
| Passed | 78 |
| Failed | 3 |
| Skipped with documented exceptions | 3 |

The scan identified three findings that remain unresolved:

| Check | Finding | Current decision |
|---|---|---|
| CKV_AWS_135 | EC2 EBS optimization | Deferred pending review of instance impact and replacement risk. |
| CKV_AWS_88 | EC2 instance has a public IP | Deferred until a private management path is planned and verified. |
| CKV_AWS_338 | CloudWatch log retention is below one year | Seven-day retention retained as a cost-conscious lab decision. |

Three additional findings—CKV_AWS_109, CKV_AWS_356, and CKV_AWS_111—were
suppressed with documented explanations for the KMS key policy. These are accepted
scanner exceptions, not passed checks, and the underlying policy must remain under
review.

### Security trade-offs

This is a learning environment, not a declaration of production readiness.
The instance still has a public IP, and the log retention period is shorter than
the one-year period recommended by Checkov. These choices are documented so they
can be revisited as the architecture and budget evolve.

The next improvements include evaluating private instance management, reviewing
the remaining Checkov findings, and incorporating security checks into an
automated infrastructure workflow.

### Tools and Services

Terraform, Checkov, AWS VPC, EC2, IAM, Systems Manager, VPC Flow Logs,
CloudWatch Logs, AWS KMS, Git, and GitHub.

### Security validation with Trivy

Trivy is integrated into GitHub Actions to scan Terraform for security
misconfigurations. The scanner is pinned to version 0.76.0, and the workflow
fails when HIGH or CRITICAL findings are detected.

#### Finding: AWS-0104 — Unrestricted Egress

**Severity:** CRITICAL
**Status:** Remediated; required CI checks passed.

Trivy identified a security group rule that permitted outbound TCP port 443
connections to any IPv4 destination (`0.0.0.0/0`).

Although the rule restricted the protocol and port, it did not restrict
the destination. This created broader outbound network access than the
CloudGuard instance required.

#### Remediation

The unrestricted egress rule was removed and replaced with a standalone
Terraform security-group egress rule.

The updated configuration permits outbound TCP port 443 only to the
CloudGuard Systems Manager VPC endpoint security group.

Two interface VPC endpoints were configured:

- `ssm`
- `ssmmessages`

Private DNS is enabled for both endpoints. The endpoint security group
allows inbound TCP port 443 from the CloudGuard EC2 security group.

#### Verification

The remediation was verified through the following checks:

- `terraform validate` completed successfully.
- `terraform plan` reported no changes after the infrastructure was reconciled.
- AWS CLI inspection confirmed that EC2 egress targets the endpoint security
  group rather than `0.0.0.0/0`.
- AWS CLI inspection confirmed that the endpoint security group permits
  inbound TCP port 443 from the EC2 security group.
- GitHub Actions passed all three checks on pull request #1, including
  Checkov Security Scan and Mandatory Terraform CI.
- The remediation was merged into `main`.

These results confirm that the infrastructure configuration was updated
and the configured CI checks passed. Successful CI checks alone do not
prove that Systems Manager connectivity works end to end; that remains
a separate verification task.

#### Engineering lesson

A restricted port does not necessarily mean restricted network access.
Security-group rules should limit both the permitted traffic and its
intended destinations. Automated security findings should be investigated
and remediated rather than suppressed simply to obtain a passing build.

## Jenkins: SCM-Integrated Terraform Security Pipeline

I integrated Jenkins with the CloudGuard GitHub repository to run automated infrastructure validation and security scanning against version-controlled Terraform code.

### Pipeline stages

The `Jenkinsfile` defines these stages:

1. **Source Checkout** : retrieves the project from GitHub and records the build and commit details.
2. **Environment Check** : verifies that Git, Terraform, and Checkov are available.
3. **Terraform Format Check** : checks Terraform formatting.
4. **Terraform Initialization** : initializes the Terraform working directory using the committed dependency lock file.
5. **Terraform Validation** : validates the Terraform configuration.
6. **Checkov Security Scan** : scans the Terraform configuration for security misconfigurations.

The pipeline uses timestamps, prevents concurrent builds of the same job, and reports success or failure through its post-build actions.

### Troubleshooting Terraform initialization

The initial Jenkins build failed during Terraform initialization because the machine could not establish an HTTPS connection to `registry.terraform.io`.

Testing confirmed that general HTTPS connectivity worked, while connections to the Terraform Registry timed out.

The AWS provider version `6.68.0` was already present in the Jenkins workspace. I configured a Terraform plugin cache for the Jenkins service account and successfully initialized the workspace using the previously installed provider.

This resolved the initialization failure in the tested workspace. The solution should continue to be verified on fresh workspaces to ensure that provider availability is reproducible.

### Security scan results

The targeted Checkov tests produced the following results when the corresponding configuration settings were enabled:

| Check | Requirement | Targeted test |
|---|---|---|
| CKV_AWS_135 | EC2 EBS optimization | Passed |
| CKV_AWS_88 | EC2 instance should not have a public IP | Passed |
| CKV_AWS_338 | CloudWatch log retention of at least one year | Passed |

The current EC2 configuration still has two outstanding findings:

- **CKV_AWS_135:** EBS optimization is disabled.
- **CKV_AWS_88:** The instance is configured with a public IP address.

Changing these settings caused Terraform to plan replacement of the existing EC2 instance. I reverted the temporary changes and did not apply that replacement.

These findings remain open for a future infrastructure redesign. They have not been suppressed merely to produce a passing scan.

### CloudWatch retention improvement

The VPC Flow Logs retention period was increased from 7 days to 365 days.

The change was applied successfully through Terraform and verified directly using the AWS CLI. Terraform reported one resource changed and no resources added or destroyed.

The configuration change was merged into main  through pull request #12, with both required GitHub Actions checks passing.

### Engineering lessons

- A successful Terraform validation does not guarantee that security policies pass.
- A successful Checkov scan does not prove that changes can be applied without infrastructure impact.
- Provider caching can help when registry connectivity is unreliable, but fresh-workspace initialization must also be tested.
- Security findings should be investigated and documented rather than hidden to obtain a green build.
- CI/CD should validate infrastructure changes without automatically applying potentially destructive modifications.

### Ansible Security Baseline Auditing

CloudGuard uses Ansible to perform repeatable security baseline checks on a Linux host. The baseline role evaluates selected system services and checks explicitly configured SSH security directives against defined expectations.

**Implemented capabilities**

- **Service auditing:** Checks the operational states of selected system services, including SSH, cron and systemd-resolved.
- **SSH configuration auditing:** Evaluates `PermitRootLogin`, `PasswordAuthentication`, `PermitEmptyPasswords` and `X11Forwarding` against a defined security baseline.
- **Finding classification:** Classifies SSH settings as `OK`, `REVIEW` or `INVESTIGATION_REQUIRED`, depending on the observed configuration.
- **Audit reporting:** Reports individual findings and summarises the number of settings that pass the baseline checks and those requiring further attention.
- **Validation and testing:** Validates the Ansible role and tests the SSH classification logic against different configuration values.
- **CI/CD integration:** Integrates the Ansible baseline audit into the existing Jenkins pipeline.

**Current limitation**

The SSH audit examines explicitly configured directives in `/etc/ssh/sshd_config`. It does not fully evaluate effective SSH settings, including configuration inheritance, included files and default values. Findings therefore require appropriate interpretation and further investigation where necessary.

The role is designed for security auditing. Its current SSH audit reports findings without changing SSH security settings.

## Docker and Container Security

### Overview

As part of the CloudGuard learning journey, I built and tested Docker containers to understand how container configuration, image vulnerabilities, and runtime permissions affect application security.

The lab compares a baseline Nginx container with an unprivileged container and a patched, hardened image. I used Trivy to scan images, updated vulnerable Alpine packages, applied runtime security controls, and verified application availability.

### 1. Baseline Container Assessment

I deployed the standard `nginx:alpine` image locally and exposed it through `127.0.0.1:8081`.

The initial assessment established a baseline for comparing container security configurations.

Identified weaknesses included:

- The container's main process runs as root.
- The container retains Docker's default capability set rather than dropping unnecessary capabilities explicitly.
- The root filesystem is writable.
- Explicit memory, CPU, and process-count limits were not configured.
- Image scanning reported vulnerabilities requiring further investigation.

The default Docker capability set is restricted compared with unrestricted host root privileges, but unnecessary capabilities can still increase the potential impact of a container compromise.

### 2. Container Runtime Hardening

I deployed an unprivileged Nginx image and applied the following controls:

| Security control | Implementation | Purpose |
|---|---|---|
| Non-root execution | UID `101` | Reduces reliance on root privileges inside the container. |
| Linux capabilities | `--cap-drop ALL` | Removes the container's Linux capabilities. |
| Read-only root filesystem | `--read-only` | Prevents modifications to the container's root filesystem. |
| Temporary writable storage | Restricted `tmpfs` mounts | Provides temporary writable paths required by Nginx. |
| Memory limit | `256 MB` | Limits container memory consumption. |
| CPU limit | `1.0` CPU | Restricts CPU allocation. |
| Process limit | `100` processes | Limits process creation within the container. |
| Localhost-only publishing | `127.0.0.1:8082:8080` | Prevents the published service from being bound to all host network interfaces. |

### 3. Runtime Verification

I verified the effective container configuration using Docker inspection and process status information.

The hardened container ran as UID `101`, with all Linux capabilities dropped and a read-only root filesystem enabled. Memory, CPU, and process limits were also confirmed.

The application returned HTTP `200 OK` through `127.0.0.1:8082`, demonstrating that the hardened configuration continued to serve HTTP requests.

### 4. Vulnerability Scanning with Trivy

I installed Trivy and used it to scan the baseline image, the original unprivileged image, and the patched image.

| Image | Reported findings | Critical | High | Medium | Low | Unknown |
|---|---:|---:|---:|---:|---:|---:|
| `nginx:alpine` | 49 | 0 | 3 | 2 | 44 | 0 |
| `nginxinc/nginx-unprivileged:stable-alpine` | 52 | 0 | 3 | 3 | 44 | 2 |
| `nginx-unprivileged-hardened:1.0` | 0 | 0 | 0 | 0 | 0 | 0 |

These are the findings reported by Trivy during the scans. They should not be interpreted as a count of unique vulnerabilities across all packages or as proof that an image contains no security weaknesses.

### 5. Vulnerability Remediation

The initial image scans identified vulnerable Alpine packages, including `brotli-libs`, `musl`, and `zlib`.

I created a derived image that upgrades installed Alpine packages and returns to the unprivileged user:

```dockerfile
FROM nginxinc/nginx-unprivileged:stable-alpine

USER root

RUN apk upgrade --no-cache

USER 101
```

I built the image as `nginx-unprivileged-hardened:1.0` and rescanned it with Trivy. The scan reported zero vulnerabilities at the time of testing.

A clean scan is evidence of the result from that particular scan, not a guarantee that the image is vulnerability-free. Future scans are necessary as vulnerability intelligence and packages change.

### 6. Hardened Image Deployment

I deployed the patched image with the same principal runtime controls used for the hardened container:

- Non-root execution as UID `101`.
- All Linux capabilities dropped.
- Read-only root filesystem.
- Temporary writable filesystems for required runtime paths.
- Memory, CPU, and process limits.
- Port publishing restricted to the host's loopback interface.

The deployed service returned HTTP `200 OK` through `127.0.0.1:8083`.

The container logs also showed a warning about modifying `/etc/nginx/conf.d/default.conf` on a read-only filesystem. Although the application started successfully, this warning is documented for further investigation rather than treated as resolved.

### 7. AppArmor and `no-new-privileges`

I attempted to enable Docker's `no-new-privileges` security option. The container failed to start, and the host audit log recorded an AppArmor denial involving execution of `/docker-entrypoint.sh` and the `no new privs` setting.

The container started successfully when I retried without that option.

This identifies a host-level security compatibility issue to investigate further. The `no-new-privileges` control was not successfully enabled, and the current container configuration should not be described as having that protection.

The appropriate next step is to investigate the interaction between the Snap-packaged Docker daemon, AppArmor, and the runtime configuration without disabling host security protections indiscriminately.

### 8. Lessons Learned

This exercise demonstrated that container security requires several complementary controls:

- Running as a non-root user reduces the privileges available to the application.
- Dropping unnecessary Linux capabilities reduces the container's effective privileges.
- Read-only root filesystems limit filesystem modification.
- Resource limits help constrain excessive CPU, memory, and process consumption.
- Vulnerability scanning helps identify outdated or vulnerable packages.
- Updating packages and rescanning provides a repeatable remediation process.
- Runtime testing verifies that security controls do not prevent the application from serving legitimate requests.
- Host security mechanisms and container runtime settings must be tested together.
- A successful application response does not, by itself, prove that every security control is effective.

### 9. Outstanding Improvements

The following tasks remain open:

1. Investigate the AppArmor denial associated with `no-new-privileges`.
2. Determine how to enable and verify `no-new-privileges` safely in this environment.
3. Investigate the Nginx read-only filesystem warning.
4. Evaluate pinning base images by digest and establishing a repeatable image-update process.
5. Integrate container image scanning into an automated CI pipeline.
6. Add container configuration and supply-chain security checks.
7. Repeat vulnerability scans periodically and document subsequent remediation.

### Tools Used

Docker, Nginx, Alpine Linux, Trivy, AppArmor, Linux capabilities, and the Linux process filesystem.

### Container Network Segmentation

#### Objective
Test how Docker user-defined bridge networks control direct communication between containers.

#### Lab Environment

Two separate user-defined bridge networks were created:

| Network | Subnet | Test workload |
|---|---|---|
| `cloudguard-app-net` | `172.18.0.0/16` | `cloudguard-app-test` and `cloudguard-peer-test` |
| `cloudguard-isolated-net` | `172.19.0.0/16` | `cloudguard-isolated-test` |

The Nginx test service was published on `127.0.0.1:18080`, limiting its published host endpoint to the host's IPv4 loopback interface.

#### Connectivity Tests

| Source | Destination | Result |
|---|---|---|
| `cloudguard-peer-test` | `cloudguard-app-test` (`172.18.0.2:80`) | HTTP request succeeded; exit code `0` |
| `cloudguard-isolated-test` | `cloudguard-app-test` (`172.18.0.2:80`) | Request timed out; exit code `1` |

The successful test also demonstrated container-name DNS resolution on the same user-defined bridge network.

The cross-network request failed, consistent with the separation of the two bridge networks. These tests establish the behavior of the tested endpoints and paths, not a guarantee that all possible paths between the networks or through the host are blocked.

#### Security Findings

- Containers sharing a user-defined bridge can communicate directly when the destination service is reachable.
- Separate bridge networks provide network-level separation and restrict direct communication between workloads that do not share a network.
- Network segmentation can reduce opportunities for lateral movement following a container compromise.
- Publishing a service on `127.0.0.1` limits its published host endpoint; it does not prevent other containers sharing a bridge network from reaching the service through its container IP.
- Containers can be attached to multiple networks, so network membership must be reviewed when assessing isolation.
- Network segmentation should complement least privilege, container hardening, vulnerability management, and host security controls.

#### Limitations

The cross-network test produced a timeout rather than a definitive network-policy audit. The lab did not test every possible host-routing, published-port, or additional-network path. Further testing would be required before claiming comprehensive isolation.

#### Tools Used

- Docker Engine
- Docker user-defined bridge networks
- Nginx Alpine image
- `docker network inspect`
- `docker exec`
- `wget`

### Container Secrets Management

#### Objective
Investigate secret exposure through container environment variables, compare environment variables with a read-only file mount, and examine Docker image-layer risks.

#### Environment Variable Exposure

A temporary container named `cloudguard-secret-env-lab` was created with a fictitious password supplied through the `DB_PASSWORD` environment variable.

Docker inspection returned the configured variable and its value. This demonstrated that users with sufficient Docker daemon access can retrieve sensitive values from container configuration.

No real credentials were used.

#### Read-Only Secret File Mount

A host-side test file was created with restrictive filesystem permissions:

- Directory permissions: `700`
- File permissions: `600`

The file was mounted into `cloudguard-secret-file-lab` at `/run/secrets/db_password` using a read-only bind mount.

Verification results:

| Test | Result |
|---|---|
| Container could read the mounted file | Passed |
| Container could write through the mount | Blocked |
| Host file permissions | Verified as `600` |
| Host directory permissions | Verified as `700` |

The read-only mount prevented modification through that mount. It did not prevent the container from reading the secret or protect the file from a sufficiently privileged host user.

This local bind-mount exercise is not equivalent to Docker Swarm secrets.

#### Docker Image-Layer Investigation

A harmless test image, `cloudguard-history-lab:1.0`, was built with two instructions:

1. Create `/demo.txt`.
2. Remove `/demo.txt` in a subsequent build step.

The image history recorded both instructions. Running a container from the final image confirmed that `/demo.txt` was absent from the final filesystem.

This demonstrates that image history and the final container filesystem provide different information. The lab did not extract an earlier layer or recover the deleted file's contents, so it does not establish that a recovery attack was completed.

#### Security Findings

- Avoid embedding credentials in Dockerfiles or image layers.
- Deleting a secret in a later build instruction does not guarantee that its earlier contents are absent from the image.
- Environment variables are convenient configuration mechanisms but can expose sensitive values through container inspection and other privileged access.
- Read-only bind mounts restrict writes through the mount but do not provide encryption or protect against privileged host access.
- Host filesystem permissions help restrict ordinary access but are not a substitute for a complete secrets-management solution.
- Docker Swarm secrets are designed for Swarm services. Swarm was inactive during this lab, so Swarm secret delivery was not tested.
- Secret-management controls must be assessed alongside Docker daemon access, host security, application behavior, and deployment configuration.

#### Limitations

The image-layer exercise demonstrated file creation and deletion across build instructions but did not recover data from an earlier layer.

A bind mount from `/tmp` failed because Docker reported that its source path did not exist, while a test bind mount from the project directory succeeded. The cause of the difference was not established and remains unresolved.

#### Tools Used

- Docker Engine 29.8.0
- Docker image history
- Docker inspection
- Read-only bind mounts
- Alpine Linux
- Linux filesystem permissions
### Container Supply-Chain Security

#### Objective

Understand Docker image tags, image IDs, and repository digests; investigate tag mutability and digest-based image references; and examine image metadata and build history.

#### Image Inventory

The following locally available images were inspected using `docker image ls --digests`.

| Repository | Tag | Image ID (short) | Reported digest (short) |
|---|---|---|---|
| `nginx-unprivileged-hardened` | `1.0` | `62293a4f94b0` | `62293a4f94b0` |
| `nginx` | `alpine` | `a3554c0d0b48` | `a3554c0d0b48` |
| `alpine` | `3.24` | `be2656061b53` | `be2656061b53` |
| `nginxinc/nginx-unprivileged` | `stable-alpine` | `f5116ed4606f` | `f5116ed4606f` |

These are observations from the local Docker environment during the lab, not universal relationships between image IDs and repository digests.

#### Image Tags and Immutable Digests

An image tag is a human-readable reference that can be reassigned to a different image.

Example:

`nginxinc/nginx-unprivileged:stable-alpine`

The `stable-alpine` tag can point to a newer image when the publisher updates the release.

A digest reference identifies specific manifest or image-index content using a cryptographic hash:

`nginxinc/nginx-unprivileged@sha256:<digest>`

Unlike a mutable tag, a digest reference identifies fixed content. Pinning an image to a verified digest improves deployment consistency and reduces the risk of unexpected image changes when a tag is updated.

Digest pinning does not guarantee that an image is vulnerability-free or that its registry will retain the referenced content indefinitely.

#### Image Inspection and Verification

The base image was inspected using Docker image inspection.

Recorded metadata included:

| Property | Observed value |
|---|---|
| Image version label | `1.30.6-alpine` |
| Image revision label | `bb7393196554e11f7ba95452856d8b5faff217bf` |
| Operating system | Linux |
| Architecture | AMD64 |
| Source repository | `nginx/docker-nginx-unprivileged` |

The hardened image, `nginx-unprivileged-hardened:1.0`, was also inspected.

Its configuration reported:

- Configured user: UID `101`
- Exposed port: `8080/tcp`
- Entrypoint: `/docker-entrypoint.sh`
- Command: `nginx -g daemon off;`

The image creation time was recorded as `2026-10-28T13:18:04.146300677+01:00`.

#### Tag and Digest Resolution Test

The base image was inspected through both its tag and its reported repository digest.

Both references successfully resolved to the same local image configuration:

`sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03`

The reported image ID and repository digest had matching SHA-256 values in this environment. This observation should not be generalized: an image ID identifies an image configuration, while a repository digest identifies a manifest or image index.

The test demonstrated successful local resolution through both references. It did not independently verify image signatures, publisher authenticity, or provenance.

#### Image Build History Investigation

The hardened image was examined using `docker history nginx-unprivileged-hardened:1.0`.

The history showed the inherited NGINX image layers and additional build instructions from the hardening Dockerfile, including:

```dockerfile
USER root
RUN apk upgrade --no-cache
USER 101

```
### Security Findings

#### Vulnerability Investigation: CVE-2025-60876

The hardened NGINX image was investigated for CVE-2025-60876, a vulnerability involving HTTP header injection in the BusyBox `wget` implementation.

**Affected component**

| Property | Observed value |
|---|---|
| Image | `nginx-unprivileged-hardened:1.0` |
| Operating system | Alpine Linux 3.24.3 |
| Package | BusyBox |
| Installed version | `1.37.0-r31` |
| Package repository | Alpine v3.24/main |
| Scanner | Grype 0.121.0 |
| Vulnerability | CVE-2025-60876 |
| Severity | Medium |

**SBOM and vulnerability scanning**

Syft catalogued 70 software packages in the image. Grype identified three package-level matches associated with CVE-2025-60876:

- `busybox`
- `busybox-binsh`
- `ssl_client`

These matches represent one underlying CVE affecting related package components, not three independent vulnerabilities.

The Grype results reported no available fixed version in its vulnerability database at the time of scanning.

**Manual vulnerability verification**

A disposable container was launched using the hardened image. A temporary Python TCP listener on the host captured the HTTP request generated by BusyBox `wget`.

The test used a URL containing an embedded carriage return and newline followed by attacker-controlled header text.

The captured request was:

```text
GET /test
X-Injected: yes HTTP/1.1
Host: 127.0.0.1:18089
User-Agent: Wget
Accept: */*
Connection: close
```

The injected text appeared within the transmitted HTTP request rather than being rejected by the expected control-character validation.

This reproduced the HTTP request-line injection behaviour associated with CVE-2025-60876 in the tested image.

**Package investigation**

The installed BusyBox package was confirmed to originate from Alpine's official v3.24/main repository.

Alpine's public security discussion and patch investigation showed that a proposed fix modified `networking/wget.c` to reject unencoded control characters and spaces in URLs. The proposed implementation also raised compatibility concerns during review.

The available investigation did not establish that a corrected package had been released for Alpine 3.24 at the time of testing.

**Security implications**

An attacker who can influence URLs supplied to the vulnerable `wget` implementation may be able to inject HTTP headers into outgoing requests.

The demonstrated behaviour establishes the vulnerability in the tested BusyBox implementation. It does not, by itself, establish remote exploitability through the NGINX application. That depends on whether an attacker can reach an application path that invokes the affected utility with attacker-controlled URLs.

**Remediation status**

Remediation remains pending.

The image should not be considered remediated until a verified corrected package or effective mitigation has been deployed and the behavioural test confirms that the injected header is rejected.

**Evidence and limitations**

- Grype vulnerability scan and JSON results.
- Syft-generated CycloneDX and SPDX SBOMs.
- Alpine package version and repository verification.
- Alpine CVE discussion and proposed patch investigation.
- Raw HTTP request captured by the local Python listener.

The test was performed using a disposable container and a local listener. No existing CloudGuard containers or production services were modified.
- Mutable image tags can introduce unexpected image changes between deployments.
- Digest pinning provides a more consistent way to identify the intended image content.
- Image IDs and repository digests serve different purposes and should not be treated as interchangeable.
- Image metadata labels provide useful information about declared versions, maintainers, and source repositories, but do not independently establish authenticity.
- Docker image history can help investigate how an image was constructed.
- Digest pinning does not replace vulnerability scanning, image provenance verification, signature verification, or runtime hardening.
- Production image updates should be verified and tested before controlled deployment.
- Security remediation should include post-deployment monitoring and documentation.

### Limitations

The exercise used locally available Docker images and metadata.

The matching image ID and reported repository digest values were observed in this environment. Their equality was not established as a general Docker behaviour.

The lab implemented CycloneDX and SPDX SBOM generation and vulnerability scanning with Grype. Image signing, signature verification, provenance attestation, and automated supply-chain policy enforcement remain outstanding.

No production deployment or running container was modified during this exercise.

### Tools Used

- Docker Engine 29.8.0
- Docker image inspection
- Docker image history
- Docker image tags and repository digest references
- NGINX Unprivileged image
- Linux and AMD64 architecture
