# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

$run = <<"SCRIPT"
echo ">>> Generating rpi image ... $@"
export DEBIAN_FRONTEND=noninteractive
export RPIGEN_DIR="${1:-/home/vagrant/rpi-gen}"
export APT_PROXY='http://127.0.0.1:3142' 
# Prepare
rsync -a --delete --exclude 'work' --exclude 'deploy' /vagrant/  ${RPIGEN_DIR}/
cd ${RPIGEN_DIR}
sudo ./clean.sh 
# Build
sudo --preserve-env=APT_PROXY ./raspbian-cloud-build.sh
# Copy images back to server
[ -d deploy ] && cp -vR deploy /vagrant/
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.  

  config.vm.define :rpigen do |rpigen|
      # Every Vagrant virtual environment requires a box to build off of.
      #rpigen.vm.box = "ubuntu/xenial32"
      rpigen.vm.box = "jriguera/rpibuilder-buster-10.1-i386"

      # Create a forwarded port mapping which allows access to a specific port
      # within the machine from a port on the host machine. In the example below,
      # accessing "localhost:8080" will access port 80 on the guest machine.
      # ubuntu.vm.network "forwarded_port", guest: 80, host: 8080

      # Create a private network, which allows host-only access to the machine
      # using a specific IP.
      # ubuntu.vm.network "private_network", ip: "192.168.33.10"
      # rpigen.vm.network "private_network", ip: "192.168.50.58"

      # Create a public network, which generally matched to bridged network.
      # Bridged networks make the machine appear as another physical device on
      # your network.
      # ubuntu.vm.network "public_network"

      # Share an additional folder to the guest VM. The first argument is
      # the path on the host to the actual folder. The second argument is
      # the path on the guest to mount the folder. And the optional third
      # argument is a set of non-required options. (type: "rsync")
      #rpigen.vm.synced_folder ".", "/home/vagrant/rpi-gen", type: "virtualbox"

      rpigen.vm.provision "shell" do |s|
        s.inline = $run
        s.args = "#{ENV['WORK_DIR']}"
      end
  end
end
