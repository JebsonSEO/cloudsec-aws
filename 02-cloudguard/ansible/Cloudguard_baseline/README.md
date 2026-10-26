# CloudGuard Baseline

A reusable Ansible role for performing read-only Linux service checks and reporting services that may require security review.

## Features

- Displays the audit name and managed host.
- Checks the state of configurable systemd services.
- Reports each service's state.
- Flags services reported as `inactive` for review.
- Summarizes the number of services checked and those requiring review.
- Supports runtime variable overrides.
- Makes no system changes during the audit.

## Requirements

- Linux system using systemd.
- Ansible Core 2.20 or later.
- Permissions to query the state of the selected services.

## Role Variables

Defined in `defaults/main.yml`:

| Variable | Default | Description |
|---|---|---|
| `audit_name` | `CloudGuard Security Audit` | Name displayed in the audit report. |
| `services_to_check` | `ssh.service`, `cron.service`, `systemd-resolved.service` | List of systemd services to inspect. |

## Example Playbook

```yaml
---
- name: Run CloudGuard Baseline Audit
  hosts: localhost
  connection: local
  gather_facts: false

  roles:
    - Cloudguard_baseline
```

## Run the Audit

From the role directory:

```bash
cd ~/cloudsec-aws/02-cloudguard/ansible/Cloudguard_baseline

ANSIBLE_ROLES_PATH=.. ansible-playbook tests/test.yml -i tests/inventory
```

## Override the Audit Configuration

Change the audit name:

```bash
ANSIBLE_ROLES_PATH=.. ansible-playbook tests/test.yml -i tests/inventory \
  -e '{"audit_name": "Production Security Audit"}'
```

Check only selected services:

```bash
ANSIBLE_ROLES_PATH=.. ansible-playbook tests/test.yml -i tests/inventory \
  -e '{"services_to_check": ["cron.service", "systemd-resolved.service"]}'
```

## Understanding Findings

A service reported as `inactive` is flagged for review. This does not automatically mean the service is vulnerable. The finding must be interpreted in the context of the host's intended configuration.

The role collects and reports service states. It does not start, stop, enable, or disable services.

## Dependencies

None.

## License

MIT, if distributed under the MIT License.

## Author

Jebson
