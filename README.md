# Use Mullvad Adblock DNS

*Beta: May have rough edges.*

I use Tailscale Magic DNS most of the time. It forwards all my DNS requests to [NextDNS](https://nextdns.io), which is great most of the time! But sometimes I want more anonymity and enable a Mullvad Wireguard VPN connection.

When I'm connected to Mullvad, I expect all traffic to go through Mullvad, including DNS requests.

Unfortunately, I found that when connected to a Mullvad VPN server while Tailscale was enabled, DNS requests were going to Tailscale while the rest of my traffic was going through Mullvad.

To fix that, I've configured the script in this repo to execute whenever I connect to or disconnect from a network. It checks if I'm connected to a Mullvad VPN server by looking for my Mullvad IP address across all network interfaces. If it finds that IP address (which is the same regardless of which Mullvad VPN server I'm connected to), it disables Tailscale's Magic DNS.

Then when I disable the Mullvad VPN connection, it re-enables Tailscale Magic DNS.

Sounds simple, but it was a bit fiddly to get right.

## Requirements

- MacOS (it can probably be ported to work on Linux, but it'd probably be easier to use Wireguard's native `PostUp` and `PostDown`, which don't work on the Mac App Store installed version of Wireguard)
- Tailscale installed as a [package](https://pkgs.tailscale.com/stable/#macos), not from the App Store. You can also install it using Homebrew: `brew install --cask tailscale`.
- Wireguard plus at least one Wireguard config from Mullvad
- Bash, `ps`, `grep`, `awk`, `head`, which should all be in a Mac OS default install

## Install

1. Clone this repository.
1. Ensure `/Library/LaunchDaemons/update-route-for-mullvad-dns.job.plist` exists with the below XML content.
2. Replace the `<string>/Users/crcastle...</string>` with the path to the shell script.
3. Replace `<string>crcastle</string>` with the username that installed Tailscale.
4. Then run `sudo launchctl load /Library/LaunchDaemons/update-route-for-mullvad-dns.job.plist` to "load" the daemon so that it will run whenever `/etc/resolv.conf` is modified.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>EnvironmentVariables</key>
	<dict>
		<key>DEBUG</key>
		<string>false</string>
	</dict>
	<key>GroupName</key>
	<string>staff</string>
	<key>InitGroups</key>
	<false/>
	<key>Label</key>
	<string>update-route-for-mullvad-dns.job</string>
	<key>LowPriorityBackgroundIO</key>
	<false/>
	<key>Program</key>
	<string>/Users/crcastle/bin/use-mullvad-adblock-dns.sh</string>
	<key>RunAtLoad</key>
	<true/>
	<key>ThrottleInterval</key>
	<integer>5</integer>
	<key>UserName</key>
	<string>crcastle</string>
	<key>WatchPaths</key>
	<array>
		<string>/etc/resolv.conf</string>
	</array>
</dict>
</plist>
```
