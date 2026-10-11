# 1Password SSH keys

SSH keys come only from 1Password's **SSH agent**: private keys stay sealed in the
vault, and the agent exposes them to `ssh` and `scp`. No key file is written to
`~/.ssh` — there is no on-disk fallback.

## Enable and wire the agent

1. 1Password app: **Settings → Developer → Use the SSH agent** (on). The key you
   need must be an **SSH Key** item in a vault the app can unlock.
2. Point the shell at its socket so plain `ssh`/`scp` use it — add to `~/.zshrc`:

```sh
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"  # macOS
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"                                          # Linux
```

Without that export, prefix each call: `SSH_AUTH_SOCK=<socket> ssh …`.

## Confirm the key is visible

```sh
ssh-add -l     # fingerprints + names; must list the key you will inject
```

Empty output means the agent is off, locked, or the key isn't an SSH Key item.
Fix that before continuing — there is nothing to fall back to.

## Register the public key with Hetzner

`ssh-add -L` prints the public keys in `authorized_keys` form; the private key
never leaves the vault:

```sh
ssh-add -L                                    # copy the line you want
hcloud ssh-key create --name <n> --public-key "<paste>"
hcloud ssh-key list                           # confirm
```

The rest of the guide runs as written: `--ssh-key <n>` injects that public key,
and `ssh root@<ip>` / `scp` authenticate through the agent.
