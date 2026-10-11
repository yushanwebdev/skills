# Idempotent SSH-access setup for a fresh Ubuntu host.
#
# Run ON the server as root, in two phases on purpose — create the door, prove
# it, then bolt the old one (prove-then-lock). Never run `harden` before you have
# logged in as <user> from your client and seen sudo work.
#
#   scp references/harden-ssh.sh root@<ip>:
#   ssh root@<ip> 'bash harden-ssh.sh user <name>'     # then prove from client
#   ssh root@<ip> 'bash harden-ssh.sh harden'          # only after proving
set -euo pipefail

usage() { echo "usage: harden-ssh.sh {user <name>|harden}" >&2; exit 2; }

create_user() {
  local u="${1:-}"
  [ -n "$u" ] || usage
  [ -s /root/.ssh/authorized_keys ] || {
    echo "no /root/.ssh/authorized_keys to copy — inject an --ssh-key at create" >&2
    exit 1
  }
  id -u "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
  usermod -aG sudo "$u"
  install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
  cp /root/.ssh/authorized_keys "/home/$u/.ssh/authorized_keys"
  chown "$u:$u" "/home/$u/.ssh/authorized_keys"
  chmod 600 "/home/$u/.ssh/authorized_keys"
  printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$u" > "/etc/sudoers.d/90-$u"
  chmod 440 "/etc/sudoers.d/90-$u"
  visudo -cf "/etc/sudoers.d/90-$u"
  echo "user '$u' ready. PROVE IT from your client before hardening:"
  echo "  ssh $u@<ip> 'sudo -n whoami'   # must print: root"
}

harden() {
  cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'CFG'
# Set by harden-ssh.sh: key-only SSH, no direct root login.
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
CFG
  chmod 644 /etc/ssh/sshd_config.d/99-hardening.conf
  sshd -t
  systemctl restart ssh 2>/dev/null || systemctl restart ssh.socket 2>/dev/null || true
  echo "hardened. VERIFY from your client:"
  echo "  ssh root@<ip> true                   # must be REFUSED"
  echo "  ssh <user>@<ip> 'sudo -n whoami'     # must print: root"
}

case "${1:-}" in
  user)   create_user "${2:-}" ;;
  harden) harden ;;
  *)      usage ;;
esac
