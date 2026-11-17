#!/bin/sh
# Installs the TESSERaCT guest tools in a Linux system, or replaces an older copy of them.
#
# They are one small program, the guest agent, that lets the TESSERaCT app on the Mac see this
# system's version and addresses, set its clock after the virtual machine was suspended, mount
# the folders shared with it and shut it down. For the tctl command on the Mac it runs
# commands here and tells what is on the screen. It talks to the app over
# the virtual machine's socket device, so none of that needs a network.
#
# Run it as root:    sudo sh install.sh
# To remove it all:  sudo sh install.sh --remove
#
# Everything it installs is in this file, in plain text, below.
set -eu

directory=/usr/local/lib/tctl
units=/etc/systemd/system

fail() {
    echo "tctl: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || fail "this has to run as root, for example: sudo sh $0"
command -v systemctl >/dev/null 2>&1 || fail "this system doesn't use systemd, which the guest agent needs"

# SSH and disc recovery must exclude an installer whose host has stopped waiting for it too.
exec 9>/run/tctl-reinstall.lock
flock -n 9 || fail "the guest tools are already being installed; wait for that installation to finish"

if [ "${1:-}" = "--remove" ]; then
    systemctl disable --now tctl-agent.service tctl-sshd-vsock.socket >/dev/null 2>&1 || true
    rm -f "$units/tctl-agent.service" "$units/tctl-sshd-vsock.socket" "$units/tctl-sshd-vsock@.service"
    # What ran this machine's setup scripts lives in the same place, and goes with it. The note that
    # they have run stays, in /var/lib/tctl: a copy of this machine goes through its first-boot
    # setup once more, and that note is what keeps the scripts from running a second time.
    systemctl disable tctl-setup.service >/dev/null 2>&1 || true
    rm -f "$units/tctl-setup.service"
    rm -rf "$directory"
    systemctl daemon-reload
    echo "The TESSERaCT guest tools are removed."
    exit 0
fi

[ -x /usr/bin/python3 ] || fail "the guest agent needs Python 3 at /usr/bin/python3. Install it and run this again"

umask 022
mkdir -p "$directory"

cat > "$directory/tctl-agent.py.new" <<'TESSERACT_END_OF_FILE'
@@tctl-agent.py@@
TESSERACT_END_OF_FILE
chmod 755 "$directory/tctl-agent.py.new"
mv -f "$directory/tctl-agent.py.new" "$directory/tctl-agent.py"

cat > "$units/tctl-agent.service" <<'TESSERACT_END_OF_FILE'
@@tctl-agent.service@@
TESSERACT_END_OF_FILE

cat > "$units/tctl-sshd-vsock.socket" <<'TESSERACT_END_OF_FILE'
@@tctl-sshd-vsock.socket@@
TESSERACT_END_OF_FILE

cat > "$units/tctl-sshd-vsock@.service" <<'TESSERACT_END_OF_FILE'
@@tctl-sshd-vsock@.service@@
TESSERACT_END_OF_FILE

# A copy of this file stays behind, for removing the tools again. It may be the file that is running,
# under another spelling of its name: then there is nothing to copy, and cp saying so is no failure.
case "$0" in
    */install.sh | install.sh) cp "$0" "$directory/install.sh" 2>/dev/null || true ;;
esac

# What older tools installed to work the desktop with. The app does that itself now.
rm -rf "$directory/agent-desktop" "$directory/desktop-install.sh" "$directory/agent-desktop-install.log"

systemctl daemon-reload
systemctl --quiet enable tctl-agent.service tctl-sshd-vsock.socket
# Restarting is what puts a newer agent in the place of a running older one.
systemctl restart tctl-agent.service
# Does nothing where systemd itself already puts the SSH server on the socket device.
systemctl start tctl-sshd-vsock.socket >/dev/null 2>&1 || true

echo "The TESSERaCT guest tools are installed."
