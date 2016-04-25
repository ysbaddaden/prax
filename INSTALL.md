= Installing Prax

Prax only requires Ruby and the Rack gem, both you should have already
installed if you are a Ruby Web developer.

=== Rubies

Prax has been developed with MRI Ruby 1.9.3 and newer, but should be
compatible with most Ruby engines like Rubinius 2+ and JRuby 1.7+ in 1.9
modes. Ruby 1.8 is deprecated, and no longer supported.

== Installing on GNU/Linux

First clone the repository somewhere (like <tt>/opt</tt> or
<tt>/usr/local/lib</tt>), and run the installer which will install the port
forwarding script and NSSwitch extension:

  $ git clone git://github.com/ysbaddaden/prax.git /opt/prax
  $ cd /opt/prax/ && ./bin/prax install

Now link your applications:

  $ cd ~/Work/myapp
  $ prax link

Point your browser to <tt>http://myapp.dev/</tt> and wait for your Rack
application to spawn.

To install Prax manually, or to review the installation process, please look at
the {prax-install}[https://github.com/ysbaddaden/prax/blob/master/libexec/prax-install]
script.

=== Ruby Version Managers

Prax being written in Ruby, version managers usually have problems to select
the correct version of Ruby or gemset (for RVM) to run Prax and to run your Rack
applications. You must
{configure Prax}[https://github.com/ysbaddaden/prax/wiki/Ruby-Version-Managers]
to handle your version manager correctly.

Please check {Prax (Crystal port)}[https://github.com/ysbaddaden/prax.cr] if
you're having too much problems installing/configuring the Ruby version of Prax.

=== Start Prax automatically

You may want to create a
{prax.desktop}[https://github.com/ysbaddaden/prax/blob/master/install/prax.desktop]
file in <tt>~/.config/autostart</tt> so that Prax will be started automatically
when GNOME starts for example. Please see with your desktop environment which
solution works best.

If you don't use X, you may add a <tt>prax start</tt> line to your
<tt>~/.bashrc</tt> for example, but be aware that it will restart Prax (and all
Rack instances) everytime you log in. That could be fixed with a
<tt>--no-restart</tt> flag and a +status+ command (contributions welcome).

=== Slowness

If you experience some regular slowness, where Prax seems to hang for periods
of 5 seconds, this is because of the DNS resolution: NSSwitch tries a real DNS
resolution before checking the prax extension. This usually creates an overhead
of less than half a second, but sometimes takes 5 seconds on my Ubuntu 12.04.

You may try to move the +prax+ NSSwitch extension before the +dns+ one, so it
looks like this:

  hosts: files mdns4_minimal [NOTFOUND=return] prax dns mdns4

This will dramatically speed up the DNS resolution of *.dev domains, and it
should never hang anymore, BUT please be aware that it may cause problems in
regular DNS resolutions (it works correctly for me).

== Mac OS X

Mac OS X isn't supported yet. Feel free to contribute!

== Features

This is an ever going work in progress, thought Prax isn't missing much things
to be on par with Pow! The current features have been implemented:

- HTTP Server
- HTTP Proxy
- HTTP Port Forwarding
- SSL support (if certs and keys are generated)
- Rack Handler (Racker)
- Rack Application spawn, restart, always restart and autokill
- Export ENV vars from a myapp/.env file
- Source ~/.praxconfig and myapp/.praxrc bash scripts
- {xip.io}[http://xip.io/] support
- GNU/Linux:
  - NSSwitch DNS resolver (resolves <tt>*.dev</tt> domains to <tt>127.0.0.1</tt>)
  - firewall rule (redirects root ports 80/443 to user ports 20559/20558)
  - install script

=== TODO

- Documentation
- Mac OS X:
  - firewall rule
  - DNS resolver
  - install script
- Commands for the prax script:
  - prax always_restart
  - prax status
  - prax start --no-restart

== Credits

- Julien Portalier <julien@portalier.com>
- Sam Stephenson, Nick Quaranto, 37signals for the sub command and Pow!
- pyromaniac for the initial NSSwitch extension
