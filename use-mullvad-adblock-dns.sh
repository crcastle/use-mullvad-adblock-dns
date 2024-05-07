#!/usr/bin/env bash
# set -euo pipefail

DEBUG="${DEBUG:-false}"
function debug {
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: $1"
  fi
}

# Set this to your Mullvad IP address. It can be the same for all Mullvad servers.
# You can get it from the Wireguard configs supplied by Mullvad.
MULLVAD_IP=""

# Set this to the absolute path of the tailscale command line executable.
# It likely doesn't need to be changed.
TAILSCALE_CMD="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

TAILSCALE_USER="$(ps aux | grep '[T]ailscale.app' | awk '{ print $1 }' | head -1)"
PID_FILE="$(dirname "$0")/.using-mullvad-dns"

# Test if a network interface contains $MULLVAD_IP, which is the
# IP address this computer uses when connected to Mullvad.
test=$(scutil --nwi | grep -c "$MULLVAD_IP")

if [ "${test}" -gt 0 ]; then
  # Connected to Mullvad Wireguard VPN, so disable Tailscale DNS
  debug "Mullvad is enabled. Disabling Tailscale DNS so that Mullvad (wireguard) DNS is used."
  sudo -u "$TAILSCALE_USER" "$TAILSCALE_CMD" up --accept-dns=false --accept-routes

  # Also add a route so DNS requests to Mullvad are routed properly
  # Some applications seem to be fine without this.
  # Others (like dig or other CLI tools) need it.
  sudo route -q -n add 100.64.0.0/24 10.65.1.1 >/dev/null 2>&1

  # Save state in a pseudo-PID file
  # We need to store state so Tailscale DNS is not
  # re-enabled if it's been disabled outside of this script
  echo "Tailscale DNS has been disabled by script $0" >"$PID_FILE"
else
  debug "Mullvad is disabled. Checking for PID file."
  if [ -f "$PID_FILE" ]; then
    debug "PID file found. Enabling Tailscale DNS."
    sudo -u "$TAILSCALE_USER" "$TAILSCALE_CMD" up --accept-dns --accept-routes

    sudo route -q -n delete 100.64.0.0/24 10.65.1.1 >/dev/null 2>&1

    rm -f "$PID_FILE"
  else
    debug "No PID file found. Doing nothing and exiting."
  fi
fi

# 1. Ensure /Library/LaunchDaemons/update-route-for-mullvad-dns.job.plist exists with the below XML content.
# 2. Replace the <string>/Users/crcastle...</string> with the path to the above script
# 3. Replace <string>crcastle</string> with the username that installed Tailscale
# 4. Then run sudo launchctl load /Library/LaunchDaemons/update-route-for-mullvad-dns.job.plist
# to "load" the daemon so that it will run whenever /etc/resolv.conf is modified

# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
# 	<key>EnvironmentVariables</key>
# 	<dict>
# 		<key>DEBUG</key>
# 		<string>false</string>
# 	</dict>
# 	<key>GroupName</key>
# 	<string>staff</string>
# 	<key>InitGroups</key>
# 	<false/>
# 	<key>Label</key>
# 	<string>update-route-for-mullvad-dns.job</string>
# 	<key>LowPriorityBackgroundIO</key>
# 	<false/>
# 	<key>Program</key>
# 	<string>/Users/crcastle/bin/use-mullvad-adblock-dns.sh</string>
# 	<key>RunAtLoad</key>
# 	<true/>
# 	<key>ThrottleInterval</key>
# 	<integer>5</integer>
# 	<key>UserName</key>
# 	<string>crcastle</string>
# 	<key>WatchPaths</key>
# 	<array>
# 		<string>/etc/resolv.conf</string>
# 	</array>
# </dict>
# </plist>
