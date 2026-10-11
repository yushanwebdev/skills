# skills

My agent skills. Each folder is a skill; `SKILL.md` is its entry point.

- [`hetzner-server/`](hetzner-server/SKILL.md) — provision and harden a Hetzner Cloud server: firewall, cloud-init, then a sudo user with root SSH disabled. SSH keys come from the 1Password agent — no file fallback.

## Using

Hand `SKILL.md` to an agent, or make it discoverable by symlinking it into your agent skills dir:

```sh
ln -s "$PWD/hetzner-server" ~/.agents/skills/hetzner-server
```
