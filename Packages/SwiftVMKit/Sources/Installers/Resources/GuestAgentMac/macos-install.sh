#!/bin/sh
# Installs the TESSERaCT guest tools in macOS, or replaces an older copy of them.
#
# They are one small program, the guest agent, that lets the TESSERaCT app on the Mac that runs this
# virtual machine see this system's version and addresses, share the clipboard with it, set its
# clock and time zone, and shut it down without a question on its screen. For the tctl command
# on that Mac it runs commands here and tells what is on the screen, once
# macOS has been told to let it. It talks to the app over the virtual machine's socket device, so
# none of that needs a network.
#
# Run it as root:    sudo sh install.sh
# To remove it all:  sudo sh /usr/local/lib/tctl/install.sh --remove
#
# Everything it installs is in this file: two launchd jobs in plain text, and the program itself,
# which is built from the TESSERaCT sources (Sources/GuestAgentMac) and written down here in Base64.
set -eu
# Whoever logs in has to be able to run the program, whatever the account that installs it likes
# its own files to be.
umask 022

directory=/usr/local/lib/tctl
program="$directory/tctl-agent"
daemon=/Library/LaunchDaemons/fr.stephan.tesseract.agent.plist
session=/Library/LaunchAgents/fr.stephan.tesseract.agent.session.plist

fail() {
    echo "tctl: $*" >&2
    exit 1
}

[ "$(uname -s)" = Darwin ] || fail "these are the guest tools for macOS, and this system isn't macOS"
[ "$(id -u)" -eq 0 ] || fail "this has to run as root, for example: sudo sh $0"

# Every transport takes the same lock. Keep its file so another attempt cannot lock a different inode.
exec 9>/var/root/tctl-reinstall.lock
lockf -t 0 9 || fail "the guest tools are already being installed; wait for that installation to finish"

# The user at the screen, in whose session the agent's other half runs. Root while nobody is logged in.
console_user=$(stat -f %u /dev/console 2>/dev/null || echo 0)

# Everyone with a session in which that half runs or is to run: the user at the screen, and those
# who switched to another user and left theirs open.
session_users() {
    {
        echo "$console_user"
        ps -axo uid=,args= | awk -v program="$program" '$2 == program && $3 == "session" { print $1 }'
    } | sort -u | grep -vx 0 || true
}

# Stops a job and waits until launchd has let go of it: only then does it take the job anew.
stop() {
    launchctl bootout "$1" >/dev/null 2>&1 || true
    tries=0
    while launchctl print "$1" >/dev/null 2>&1 && [ "$tries" -lt 50 ]; do
        sleep 0.1
        tries=$((tries + 1))
    done
}

stop_agents() {
    stop system/fr.stephan.tesseract.agent
    for user in $(session_users); do
        stop "gui/$user/fr.stephan.tesseract.agent.session"
    done
}

if [ "${1:-}" = "--remove" ]; then
    stop_agents
    rm -f "$daemon" "$session" /var/run/tctl-agent.sock /var/run/tctl-agent-jobs.sock
    rm -rf "$directory"
    echo "The TESSERaCT guest tools are removed."
    exit 0
fi

mkdir -p "$directory"
chmod 755 "$directory"

base64 -D > "$program.new" <<'TESSERACT_END_OF_FILE'
@@tctl-agent@@
TESSERACT_END_OF_FILE
chmod 755 "$program.new"
if ! "$program.new" --version >/dev/null 2>&1; then
    rm -f "$program.new"
    fail "the guest agent doesn't run on this version of macOS ($(sw_vers -productVersion))"
fi

# A copy of this file stays behind, for removing the tools again. It may be the file that is running,
# under another spelling of its name: then there is nothing to copy, and cp saying so is no failure.
case "$0" in
    */install.sh | install.sh) cp "$0" "$directory/install.sh" 2>/dev/null || true ;;
esac
# Sent over SSH it arrives for one account's eyes only. There is nothing in it to hide.
chmod 644 "$directory/install.sh" 2>/dev/null || true

# What older tools installed to work the desktop with. The app does that itself now.
rm -rf "$directory/agent-desktop" "$directory/desktop-install.sh" "$directory/agent-desktop-install.log"

# Stopping first is what puts a newer agent in the place of a running older one.
users=$(session_users)
stop_agents
mv -f "$program.new" "$program"

# The half that runs as root and answers the app.
cat > "$daemon" <<'TESSERACT_END_OF_FILE'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>fr.stephan.tesseract.agent</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/local/lib/tctl/tctl-agent</string>
		<string>daemon</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
</dict>
</plist>
TESSERACT_END_OF_FILE

# The half that runs in the session of whoever logs in at the screen: for the clipboard, and for
# what is on the screen.
cat > "$session" <<'TESSERACT_END_OF_FILE'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>fr.stephan.tesseract.agent.session</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/local/lib/tctl/tctl-agent</string>
		<string>session</string>
	</array>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
</dict>
</plist>
TESSERACT_END_OF_FILE
chmod 644 "$daemon" "$session"

launchctl bootstrap system "$daemon" || fail "launchd didn't take the guest agent"
# Whoever is logged in right now gets the clipboard at once; everyone else when they log in.
for user in $users; do
    launchctl bootstrap "gui/$user" "$session" >/dev/null 2>&1 || true
done

echo "The TESSERaCT guest tools are installed."
