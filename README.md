# Manual install instructions

## Preamble
1. Get your brew prefix
```
brew --prefix
```


## Uninstall `puma-dev` as a user service:
```
puma-dev -uninstall
```

## Install and configure `dnsmasq`
```
brew install dnsmasq
```

### Configure `dnsmasq` to route `test` domains to localhost

## Add a `dnsmasq` configuration to route all `*.test` addresses to localhost

Place the file at  `${BREW_PREFIX}$/etc/dnsmasq.d/caddy-dev.conf`
```
# Route all *.test addresses to localhost
address=/.test/127.0.0.1

# Don't read /etc/resolv.conf or any other configuration files.
no-resolv
# Never forward plain names (without a dot or domain part)
domain-needed
# Never forward addresses in the non-routed address spaces.
bogus-priv
```

### Setup `dnsmasq` as a service
```
sudo brew services start dnsmasq
```

### Add an `/etc/resolver/test` record that points to `dnsmasq` 

Place the file at `/etc/resolver/test`
```
# Necessary for caddy-dev to resolve this TLD
nameserver 127.0.0.1
```

## Install Caddy

```
brew install caddy
```

## Add `~/.caddy-dev`

This is where you'll store all of the Caddyfiles you want to use for local development. Similar to `puma-dev`, you can create as many as you need. However, you have a few distinct advantages over `puma-dev`:

* You can `import` other Caddyfiles, such as importing a repo-shared Caddyfile
* You can customize the server per target
* You don't have to make a file for every domain. If you just want a massive Caddyfile, go for it!

```
mkdir ~/.caddy-dev/
touch ~/.caddy-dev/.keep
mkdir ~/.caddy-dev/imports
touch ~/.caddy-dev/imports/.keep
echo "import imports/*" >> ~/.caddy-dev/Caddyfile
```


For now, you will also need to create the `caddy-dev` script in here, until I write a Homebrew fromula. Make sure it can be executed (`chmod a+x`):

```
#!/bin/bash

/opt/homebrew/bin/caddy run --config ~/.caddy-dev/Caddyfile --watch
```


### Setup `caddy-dev` as a service

*If you want to run `caddy-dev` in the foreground until I write the Homebrew formulae, you can ignore this step.* 

This is a modified version of the default Homebrew caddy service. This is necessary to ensure the `--watch` argument is passed, which is required for auto-reloading, and to point to your home directory

You will have to manually place the file and load it (until I write a homebrew formulae).

Place the file at `~/Library/LaunchAgents/test.practical-computer.caddy-dev.plist`

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>EnvironmentVariables</key>
  <dict>
    <key>XDG_DATA_HOME</key>
    <string>/opt/homebrew/var/lib</string>
  </dict>
  <key>KeepAlive</key>
  <true/>
  <key>Label</key>
  <string>test.practical-computer.caddy-dev</string>
  <key>LimitLoadToSessionType</key>
  <array>
    <string>Aqua</string>
    <string>Background</string>
    <string>LoginWindow</string>
    <string>StandardIO</string>
    <string>System</string>
  </array>
  <key>ProgramArguments</key>
  <array>
    <string>sh</string>
    <string>-c</string>
    <string>~/.caddy-dev/caddy-dev</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>/opt/homebrew/var/log/caddy-dev.log</string>
  <key>StandardOutPath</key>
  <string>/opt/homebrew/var/log/caddy-dev.log</string>
</dict>
</plist>
```

Then load it with:
```
launchctl load -w ~/Library/LaunchAgents/test.practical-computer.caddy-dev.plist
```