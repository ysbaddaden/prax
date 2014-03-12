---
layout: application
title: Prax
---

<div class="row" id="facts">
  <div class="small-4 columns">
    <p>Starts your Rack apps when needed.</p>
  </div>

  <div class="small-4 columns">
    <p>Access your apps from simple domains.</p>
  </div>

  <div class="small-4 columns">
    <p>Never manipulate /etc/hosts anymore.</p>
  </div>
</div>

Prax is a pure ruby alternative to [Pow!!](http://pow.cx/) that runs on
GNU/Linux.

## Quick Start

Provided you are on GNU/Linux (Mac OS X isn't supported yet), and that you have
Ruby and the Rack gem installed. sudo privilege is required to install the
NSSwitch extension, to configure /etc/nsswitch.conf and install the iptables
script:

    $ sudo git clone git://github.com/ysbaddaden/prax.git /opt/prax
    $ cd /opt/prax/
    $ ./bin/prax install

([Review the install script](https://github.com/ysbaddaden/prax/blob/master/libexec/prax-install)).

<!--Prax supports Ruby 1.9+ and JRuby 1.7+ and Rubinius 2.0 (both in 1.9 mode).
Ruby 1.8.7 support shall disappear soon.-->

## How does it work?

Prax is a web server that will start your Rack application in the background,
then proxy all requests to that application. Link your apps into the *~/.prax*
folder and then access your app by the name of the link. For instance for an
app named myapp:

    $ cd ~/.prax
    $ ln -s ~/Work/myapp .
    $ firefox http://myapp.dev

You may link the same application under different names. All requests to those
domains will be proxied to the same app. It also works for subdomains: pointing
your browser to *sub.myapp.dev* will simply proxy the request to *myapp.dev*.

    $ ln -s ~/Work/myapp otherappname
    $ firefox http://subdomain.otherappname.dev

Easy multiple domains and subdomains development!

<!--
## Why a pure-ruby alternative?

My GNU/Linux fork of [Pow](http://pow.cx/) just broke on me badly, and I
couldn't read, less write the coffeescript it's written in. I thus decided to
try writing an alternative in Ruby. Good for me, because I now have a viable
alternative, and learned a lot about TCP and UNIX sockets, the HTTP protocol,
Rack and Ruby Threads.

Also, Prax only requires Ruby and the Rack gem, both you should have already
installed if you are a Ruby Web developer.

### Rubies

Prax has been developed with MRI Ruby 1.9.3, but should be compatible with most
ruby engines. It has been tested on:

  - Ruby 1.8.7
  - Ruby 1.9.3
  - Rubinius 2.0.0 (HEAD)
  - JRuby 1.7.0 (1.9 mode)

Please note that Ruby 1.8.7 and Rubinius in 1.8 mode also require the `sfl`
(spawn for legacy) gem, because Ruby 1.8 doesn't support `Process.spawn` which
was introduced in Ruby 1.9.

Jruby in 1.8 mode isn't supported, because `sfl` requires `fork` which isn't
available on all platforms (not even GNU/Linux). Also, Jruby 1.6.8 just doesn't
work with Prax, neither in 1.8 nor 1.9 modes.

## Installing on GNU/Linux

First clone the repository, install the port forwarding script and NSSwitch
extension.

    $ git clone git://github.com/ysbaddaden/prax.git

    $ cd prax/
    $ ./bin/prax install

And you're done! You only need to link your apps using:

    $ ./bin/prax link ~/Work/myapp

Or install manually:

    $ sudo cp install/initd /etc/init.d/prax
    $ sudo chmod +x /etc/init.d/prax
    $ sudo update-rc.d prax defaults
    $ sudo /etc/init.d/prax start

    $ cd prax/ext/
    $ make
    $ sudo make install

Edit `/etc/nsswitch.conf` and add `prax` to the `hosts` line, then
restart your browser, otherwise it won't use the newly configured prax
resolver.

Create the `~/.prax` directory and link your apps to it. You may
link the same folder multiple times as different names to serve it from
different domains.

    $ mkdir ~/.prax
    $ ln -sf ~/Work/myapp ~/.prax/

Eventually start `bin/prax` to run Prax, point your browser to
`http://myapp.dev/` and wait for your Rack app to spawn.

#### Slowness

If you experience some regular slowness, where Prax seems to hang for periods
of 5 seconds, this is because of the DNS resolution: NSSwitch tries a real DNS
resolution before checking the prax extension. This usually creates an overhead
of less than half a second, but sometimes takes 5 seconds on my Ubuntu 12.04.

You may try to move the `prax` NSSwitch extension before the `dns` one, so it
looks like this:

    hosts: files mdns4_minimal [NOTFOUND=return] prax dns mdns4

This will dramatically speed up the DNS resolution of `*.dev` domains, and it
should never hang anymore. BUT please be aware that it may cause problems in
regular DNS resolutions!

### Mac OS X

Mac OS X isn't supported yet. Feel free to contribute!

## Features

This is a work in progress, and Prax is missing some features to be on par
with Pow. Mostly on the configuration side of your development machine. Yet
it's already capable to start the HTTP server, spawn your apps, proxy
requests, and more.

- HTTP Server
- HTTP Proxy
- Rack Handler (Racker)
- Rack Application spawn / restart / always restart
- SSL support (if certs and keys are generated)
- [xip.io](http://xip.io/) support
- GNU/Linux:
  - NSSwitch DNS resolver (resolves `*.dev` domains to 127.0.0.1)
  - firewall rule (redirects root ports 80/443 to user ports 20559/20558)
  - install script

### TODO

- Mac OS X:
  - firewall rule
  - DNS resolver
  - install script

## Credits

- Julien Portalier <julien@portalier.com>
- Sam Stephenson, Nick Quaranto, 37signals for the sub command
- pyromaniac for the initial NSSwitch extension
-->

