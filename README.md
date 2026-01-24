# `caddy-dev`: a small utility script for Caddy to behave like `puma-dev`

It's possible to replace `puma-dev` with 2 off-the-shelf programs:

1. [`dnsmasq`](https://dnsmasq.org/doc.html) to act as a DNS server for the `.test` domain
2. [`caddy`](https://caddyserver.com) to act as the actual HTTP(S) server

## But why?

`puma-dev` has been great! But the nature of HTTP servers & local development has fundamentally changed since it was first created:

* `puma-dev` only supports HTTP/1, when apps are expecting to run HTTP/2 in production. This means that your development environment is probably slower than production (when it comes to handling requests)
* `caddy` ships with **a ton** of features out of the box, including:
  * Compression encoding
  * Header manipulation
  * Automatic HTTPS certificate issuing (including using a local CA)
  * Live reloading (via the `--watch` command)
  * Nested `import` support
* `puma-dev`'s approach of auto-booting processes in the background does not play well with containerized apps or running servers in foreground processes
  * `puma-dev` **does** have a reverse proxy functionality, which I've used and love, but the other problems above still stand.

I've noticed the performance slowdown when working with apps that expect HTTP/2 support (especially for resource loading), and I've been genuinely impressed by `caddy` as a development server.

## How does this work?

This setup is composed of the following components/bits:

1. A record in your DNS resolver (`/etc/resolver/*` on macOS) to point everything the `test` TLD to your local machine
2. Running `dnsmasq` as a service, with a rule to route all `.test` addresses to localhost
   * You can actually run whatever DNS server you want; I just chose `dnsmasq` because it is installable via Homebrew and is easy to configure
3. A `caddy` instance that runs with `.caddy-dev/Caddyfile` as its config file and auto-reloads any changes
   * This is what the `caddy-dev` script does!

You can see the individual files that build up to this in the repo, and I'll explain them in a bit of detail below:

### `~/.caddy-dev`, like `./puma-dev` but supercharged

This is where you'll store all the Caddyfiles you want to use for local development. Similar to `puma-dev`, you can create as many as you need. However, you have a few distinct advantages over `puma-dev`:

* You can `import` other Caddyfiles, such as importing a repo-shared Caddyfile
* You can customize the server per target
* You don't have to make a file for every domain. If you just want a massive Caddyfile, go for it!

### It's Just Caddy!

The great thing about this setup is that you're just running `Caddy`. A configuration change didn't apply? Reload!

```sh
cd ~/.caddy-dev
caddy reload
```

## Homebrew installer

There is a **very** *pre-alpha* Homebrew formula you can use to:
* Install the `caddy-dev` script (and `dnsmasq`/`caddy` as dependencies)
* Add the `dnsmasq` configuration file
* Get instructions for how to finish the installation in the "Caveats" section

You can install it using:

```sh
brew install practical-computer/tap/practical-computer-caddy-dev
```

*The name is godawful because this is pre-alpha, and I do eventually want to get a nicer version of this shipped into `homebrew/core`.*

### Setting up `dnsmasq` as a root service

Currently, `dnsmasq` via Homebrew on macOS requires it to be run as `root`. You can setup its service using:

```sh
sudo brew services start dnsmasq
```

## Uninstalling the `puma-dev` service

If you've been using `puma-dev`, you do not need to uninstall the `puma-dev` package to use this. You will, however, need to uninstall the **service** that runs `puma-dev` in the background. This is because both `puma-dev` and `caddy` will try to use the standard HTTP/HTTPS ports, so you will run into conflicts.

```sh
puma-dev -uninstall
```

### Make sure to follow the caveats!

Until I write a more expanded version of the script to finish the installation on-demand, you will need to manually finish the installation due to Homebrew's sandboxing instructions.

## Manual explanation

There's nothing specific about the Homebrew installation; you can also manually install it and customize this setup to your heart's desire.

### DNS resolver record

This record tells your operating system to send any DNS queries for the `test` domain to `127.0.0.1`, so that your computer can resolve them using its own DNS server (`dnsmasq` in my case).

The file is here: [`/blob/main/resolver.test`](/blob/main/resolver.test). It actually needs to be named `/etc/resolver/test` for your system to use it for routing the `test` domain

### DNS server configuration

The `dnsmasq` configuration routes all `*.test` requests to `localhost`, with some barebones configurations to keep the server focused.

The file is here: [`/blob/main/caddy-dev.conf`](/blob/main/caddy-dev.conf). If you're using Homebrew, you need to in `${BREW_PREFIX}$/etc/dnsmasq.d/caddy-dev.conf`

### The `caddy-dev` script

`caddy-dev` itself is (currently) a one-line script that tells `caddy` to run, using 

```sh
caddy run --config ~/.caddy-dev/Caddyfile --watch
```

It's meant to act as an aid. You could run this command yourself, but I've written the script to make it easier.

## `.caddy-dev` bootstrap commands

Here's a quick series of shell commands to bootstrap `.caddy-dev`

```sh
mkdir ~/.caddy-dev/
touch ~/.caddy-dev/.keep
mkdir ~/.caddy-dev/imports
touch ~/.caddy-dev/imports/.keep
echo "import imports/*" >> ~/.caddy-dev/Caddyfile
```


# Contributors welcome!

If you'd like to help, reach out!

# Thanks, prior art, and research

* `puma-dev`: https://github.com/puma/puma-dev
* https://andre.arko.net/2023/03/05/caddy-puma-dev-for-local-development-with-custom-domains-and-https/
* https://maxschmitt.me/posts/local-subdomains-dnsmasq-caddy
* https://vninja.net/2020/02/06/macos-custom-dns-resolvers/
* https://tobiasmaier.info/posts/2024/10/27/linux-puma-dev-caddy.html
* https://mvogelgesang.com/blog/20240419/creating-a-simple-homebrew-formula/
