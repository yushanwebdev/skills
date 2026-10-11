# 1Password SSH keys

1Password can be the SSH key store: private keys stay sealed in the vault, and its
**SSH agent** exposes them to `ssh` and `scp`. Nothing lands in `~/.ssh`.

## Wire the agent

Turn it on in 1Password: **Settings → Developer → Use the SSH agent**.

Point your shell at its socket so plain `ssh` uses it — add to `~/.zshrc`:

```sh
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"  # macOS
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"                                          # Linux
```

Or scope it to one call: `SSH_AUTH_SOCK=<socket> ssh …`.

## See the keys

```sh
ssh-add -l     # fingerprints + names, once the socket is set
```

## Register a public key with Hetzner

`ssh-add -L` prints the public keys in `authorized_keys` form — no private key
needed:

```sh
ssh-add -L                                    # copy the line you want
hcloud ssh-key create --name <n> --public-key "<paste>"
hcloud ssh-key list                           # confirm
```

Now the guide runs unchanged: `--ssh-key <n>` injects it, and `ssh root@<ip>`
authenticates through the agent. If the agent is your default socket, no key
file is involved anywhere.
