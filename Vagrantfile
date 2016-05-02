Vagrant.configure("2") do |config|
  config.ssh.forward_agent = true

  config.vm.box = "ubuntu/trusty64"
  config.vm.box_check_update = false
  config.vm.hostname = 'prax'

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 4343

  config.vm.provider :virtualbox do |vb, override|
    vb.gui = false
  end

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "fgrehm/trusty64-lxc"
    lxc.container_name = config.vm.hostname
  end

  config.vm.define :rvm do |app|
    app.vm.provision :shell, inline: <<-SH
    set -e
    sudo apt-get install iptables --yes

    gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
    curl -sSL https://get.rvm.io | bash -s stable

    addgroup vagrant rvm
    echo "source /usr/local/rvm/scripts/rvm\nrvm use 2.1" | sudo -u vagrant tee /home/vagrant/.praxconfig
    echo "install: --no-ri --no-rdoc --env-shebang\nupdate: --no-ri --no-rdoc --env-shebang" | sudo -u vagrant tee /home/vagrant/.gemrc

    source /usr/local/rvm/scripts/rvm
    rvm install 2.1
    rvm use 2.1 && gem install rack

    rvm install 1.9
    rvm use 1.9 && gem install rack
    SH
  end
end
