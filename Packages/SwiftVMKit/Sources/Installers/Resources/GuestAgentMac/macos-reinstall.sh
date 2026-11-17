#!/bin/sh
# launchd keeps this job alive while the installer boots out the agent's own job.
set -eu
umask 077
d=/var/root/tctl-reinstall-@@token@@
mkdir "$d"
# The agent cannot read removable volumes without macOS asking permission. Receive the installer
# through its command input instead, and never run an incomplete transfer.
cat > "$d/install.sh"
[ "$(shasum -a 256 "$d/install.sh" | cut -d ' ' -f 1)" = '@@sha256@@' ]
cat > "$d/run.sh" <<'TESSERACT_RUNNER'
#!/bin/sh
cd /var/root/tctl-reinstall-@@token@@ || exit 1
if /bin/sh ./install.sh > install.log 2>&1; then
    echo ok > status.new
else
    printf 'failed: ' > status.new
    tail -c 2000 install.log >> status.new
fi
mv status.new status
TESSERACT_RUNNER
# Submitted jobs are kept alive by launchd; a one-shot plist must not reinstall every time it exits.
cat > "$d/job.plist" <<'TESSERACT_JOB'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>fr.stephan.tesseract.reinstall.@@token@@</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>/var/root/tctl-reinstall-@@token@@/run.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
TESSERACT_JOB
launchctl bootstrap system "$d/job.plist"
