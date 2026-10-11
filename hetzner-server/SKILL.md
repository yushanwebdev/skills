---
name: hetzner-server
description: Set up a new Hetzner Cloud server end to end — firewall, cloud-init, and a hardened sudo user with root SSH disabled.
disable-model-invocation: true
---

# Hetzner server setup

Provision a Hetzner Cloud server and leave it with **one hardened door**: a sudo
user over SSH keys, root login closed. The purpose is open — web host, media box,
agent host — because the stack that runs on it is cloud-init's job, not this
guide's.

One rule carries the whole guide, **prove-then-lock**: build the new door and
prove it opens *before* you bolt the old one. Every lockout comes from locking
first.

## 0. Prerequisites

On the machine you run this from; set up whatever's missing first.

| Need | Check | If missing |
|---|---|---|
| `hcloud` CLI | `command -v hcloud` | `brew install hcloud`, or the release binary |
| an SSH keypair | `ls ~/.ssh/*.pub`, or `ssh-add -l` lists one | `ssh-keygen -t ed25519 -f ~/.ssh/<key>`, or the 1Password agent — `references/1password.md` |

Keys may live in files or in 1Password's SSH agent; every later step works either
way. Decide too: the **sudo username** and the **ports** your purpose needs.
`ssh` and `scp` ship with the OS.

**Done when** both checks pass.

## 1. Auth

```sh
hcloud context create <name>      # paste a project-scoped token at the prompt
```

The token must be **project-scoped** (project → Security → API tokens), not an
account-wide one.

**Done when** `hcloud server list` runs without an auth error.

## 2. Pick type and location from live data

Type names and prices are not stable — Hetzner repriced and renamed the shared
line in 2026, so notes from memory (a cheap `CPX21`) read wrong today. Pin from
the API. The `CX` line is the usual value pick for a small box.

```sh
hcloud server-type list           # exact names, cores, memory, disk, price
hcloud location list
```

**Done when** the exact type name you will pass exists in the target location.

## 3. Firewall

`hcloud firewall create --rules-file` takes a **bare JSON array** of rules. The
`{"rules": […]}` wrapper the API reference shows is rejected — start from
`references/firewall.json` (SSH + HTTP/HTTPS) and add your purpose's ports.

```sh
hcloud firewall create --name <fw> --rules-file references/firewall.json
```

**Done when** `hcloud firewall describe <fw>` lists every rule you intend.

## 4. Provision

cloud-init bootstraps the box: installs packages, writes files, runs commands on
first boot. `references/cloud-init.yaml` is the base — edit it for your stack.

```sh
hcloud server create \
  --name <server> --type <type> --location <loc> --image ubuntu-24.04 \
  --ssh-key <key> --firewall <fw> \
  --user-data-from-file references/cloud-init.yaml
```

Use `--location` (datacenters are gone). `--ssh-key` takes a registered key name
(`hcloud ssh-key list`); register one from your agent's public key if it lives in
1Password — `references/1password.md`. It lands in root's `authorized_keys`.

**Done when** `hcloud server list` shows the server `running` and
`hcloud server ip <server>` returns an address.

## 5. Get in — and prove the new door

```sh
scp references/harden-ssh.sh root@<ip>:
ssh root@<ip> 'bash harden-ssh.sh user <name>'    # creates the sudo user
```

Then, from **your client** — not the server — prove the door opens:

```sh
ssh <name>@<ip> 'sudo -n whoami'    # must print: root
```

**Done when** that prints `root`. If it does not, fix it now: root is still open,
so you still can.

## 6. Lock

```sh
ssh root@<ip> 'bash harden-ssh.sh harden'    # root off, password auth off
```

It writes `/etc/ssh/sshd_config.d/99-hardening.conf`, validates with `sshd -t`
before restarting ssh, then restarts. (sshd takes the first value in glob order;
a stock image's `sshd_config.d` is empty, so `99-` is fine — only if another
drop-in sets these keys must this one sort earlier.) Prove both halves from
**your client**:

```sh
ssh root@<ip> true                   # must be REFUSED
ssh <name>@<ip> 'sudo -n whoami'     # must print: root
```

**Done when** root is refused *and* the user is still in. Both, or it is not done.

Locked out anyway? Hetzner's console is the **break-glass**: reset the root
password in the web console, open its VNC console, log in there, and repair
`authorized_keys`. The console bypasses SSH entirely. Rescue mode is the heavier
fallback.

## 7. Reprovision? Fold 4–6 in — with one caveat

A rebuild should land hardened, not re-run this by hand. Bake the user and
`99-hardening.conf` into `references/cloud-init.yaml` (pieces are there to copy).
Caveat: first boot cannot *prove* the new door from a client, so a cloud-init
that disables root on boot skips prove-then-lock entirely — keep the console
break-glass in reach until you have logged in once and confirmed the user works.

## References

- `references/firewall.json` — rule example (bare array); add your ports.
- `references/cloud-init.yaml` — bootstrap template.
- `references/harden-ssh.sh` — `user` / `harden`, idempotent.
- `references/1password.md` — the 1Password SSH agent as the key source.
