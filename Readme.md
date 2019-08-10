# Raspbian Cloud

Goal of this project: build a core base image for Raspberry Pi based on Raspbian
with boot auto-configuration, no need configure manually with ssh or other
provisioning tools. There are 2 ways to perform automatic configuration (both togeter
also possible):

1. Using `cloud-init`, for advanced users. It uses NoCloud datasource using
the fat32 boot partition. More information: https://cloudinit.readthedocs.io/en/latest/

2. Using `confinit`, via yaml file in boot partition: https://github.com/jriguera/confinit

## Features

1. Automatic provisioning at boot (via confinit and/or cloud-init)
  * Confinit, based on yaml and template rendering at boot time: https://github.com/jriguera/confinit
  * Cloud-init: https://cloudinit.readthedocs.io/en/latest/
2. Core services pre-configured: Rng-tool, Docker, Dnsmasq, Prometheus node exporter, Opensmtpd, OpenSSH, Hostapd, Monit
3. Dnsmasq primarily for dns caching and control, optionally DHCP server for Hostapd (wifi)
4. Opensmtpd pre-setup for external smarthost and local mail delivery
5. Prometheus node exporter for external monitoring.
6. Hostapd for automatic WIFI AP.
7. Monit to manage core services, monitor and alert with PAM support listening on port 2812
8. Data persistence on btrfs `/data` mountpoint with RAID 1 support. Automatically monitoring, setup and repair
  * RAID Montioring and automatic repair.
  * Automatic RAID creation/rebalance at boot time if 2 devices are provided.
9. Automatic backups of `/data` mountpoint to S3, GCS, Google Drive, ...
  * Using BetterClone: https://github.com/jriguera/betterclone
  * Based on rclone: https://rclone.org/
  * Btrfs snapshots before rclone backup.
  * Automatic backup and snapshot management: how many backups/snapshots to keep in local and remotely.
  * Automatic restore from remote at boot time.
10. Pure systemd configuration, no sys-v-init folders and services, functionally moved to
   systemd equivalent services
  * systemd-cron instead of cron
  * systemd-watchdog
  * systemd-timesyncd instead of ntpd
  * journal logging instead of rsyslog
11. Docker and docker-compose setup
  * Automatic refesh/cleanup of images
  * Volumes on `/data` partition for backups and reliable storage
  * Portainer automatically deployed by default: https://www.portainer.io/
12. Useful tools like gotop and lazydocker


Having a core server properly setup (monitoring, smpt, dns), the idea is extending the
functionality or via Docker images, which automatically will be updated when a new version
is pushed to Docker Registry (DockerHub).


# Buiding it

You can build it locally by running `sudo ./raspbian-cloud-build.sh` but then you
need to install all the dependencies defined in https://github.com/RPi-Distro/pi-gen 
and use root. This way will work but it is not recommended (there is also a bug in qemu
which makes it difficult to perform: https://github.com/RPi-Distro/pi-gen/issues/271)

The best way is just using `Vagrant` and the rpi-builder image (Debian Buster 32bits with
all dependencies and apt-cacher-ng) from https://github.com/jriguera/packer-rpibuilder-vagrant
Install Vagrant: https://www.vagrantup.com/ and Virtualbox: https://www.virtualbox.org.
If you are using Debian or Ubuntu, just install them with APT. 

Run:
```
vagrant up
```

The RaspbianCloud images will appear in `deploy` folder, ready to install.
If you want to change build steps and/or run again, type:
```
vagrant provision
```

If you made a lot of mistakes and the image is not being created, destroy the vm
and start again:
```
vagrant destroy
vagrant up
```

Is always better do `vagrant provision` because the VM includes `apt-cacher-ng` to
automatically proxy cache all APT Http request, second time will be really fast!

The process generated 2 images:

* `deploy/YYYY-MM-DD-RaspbianCloud-lite.img`: traditional sys-v-init services: cron, ntp, rsyslog, ...
* `deploy/2019-08-10-RaspbianCloud-optimized.img`: pure systemd sevices (systemd-cron, systemd-timesyncd, journal, ...)


# Using it

[Etcher](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) 
is typically the easiest option for most users to write images to SD cards, 
so it is a good place to start. If you're looking for more advanced options on Linux, 
you can use the standard command line tools below.

**Note**: use of the `dd` tool can overwrite any partition of your machine. If you 
specify the wrong device in the instructions below, you could delete your primary Linux
partition. Please be careful.

## Discovering the SD card mountpoint and unmounting it

1. Run `lsblk` to see which devices are currently connected to your machine.

2. If your computer has a slot for SD cards, insert the card. If not,
   insert the card into an SD card reader, then connect the reader to your computer.

3. Run `lsblk` again. The new device that has appeared is your SD card (you can also
   usually tell from the listed device size). The naming of the device will follow the
   format described in the next paragraph.

4. The left column of the results from the `lsblk` command gives the device name of
   your SD card and the names of any partitions on it (usually only one, but there may
   be several if the card was previously used). It will be listed as something like
   `/dev/mmcblk0` or `/dev/sdX` (with partition names `/dev/mmcblk0p1` or `/dev/sdX1`
   respectively), where X is a lower-case letter indicating the device (eg. `/dev/sdb1`).
   The right column shows where the partitions have been mounted (if they haven't been,
   it will be blank).

5. If any partitions on the SD card have been mounted, unmount them all with `umount`,
   for example `umount /dev/sdX1` (replace sdX1 with your SD card's device name, and 
   change the number for any other partitions).


## Copying the image to the SD card

In a terminal window, write the image to the card with the command below, making sure you
replace the input file `if=` argument with the path to your `.img` file, and the `/dev/sdX` 
in the output file `of=` argument with the correct device name. This is very important,
as you will lose all the data on the hard drive if you provide the wrong device name. 
Make sure the device name is the name of the whole SD card as described above, not just
a partition. For example: sdd, not sdds1 or sddp1; mmcblk0, not mmcblk0p1.

```
    dd bs=4M if=2018-11-13-raspbian-stretch.img of=/dev/sdX conv=fsync
```
Please note that block size set to 4M will work most of the time. If not, try 1M, although
this will take considerably longer. Also note that if you are not logged in as root 
you will need to prefix this with sudo.


# Configuration

Once you have copied the image to a SD card, mount it (or just remove it from the reader
and insert it again) and go to the `boot` partition (it is a fat partition) and inside the
folder `config` you will find a `parameters.yml` file. In that file you have an example of
all parameters you can setup to get the Raspbian ready when it boots.


```
# Variables used in templates
# https://gist.github.com/kimus/9315140

system:
  forceresolvconf: false
  forceipv4: true
  domain: 'local'
  hostname: raspi
  country: ES
  timezone: 'Europe/Amsterdam'
  lang: 'en_GB.UTF-8'
  user:
    name: 'pi'
    email: 'hola@gmail.com'
    password: 'raspberry'
  monit:
    users:
      monit: 'admin'
      guest: 'guest read-only'
    alerts:
      fs: '90% for 5 times within 15 cycles'
      system:
        load1: 6
        load5: 4
        mem: '98% for 10 cycles'
        cpu: '95% for 10 cycles'
        swap: '1%'
      eth0:
        upload: "100 MB in last hour"
        download: "100 MB in last hour"
      wlan0:
        upload: "100 MB in last hour"
        download: "100 MB in last hour"

networking:
  eth0:
    profile: 'dhcp'
    fallback:
       ip: '192.168.1.10/24'
       gw: '192.168.1.1'
       dns:
       - 127.0.0.1
       - 1.1.1.1
       - 8.8.8.8
# wlan0:
#   profile: 'static'
#   ip: 10.1.1.1/24
#   forward: 'eth0'
#   nolink: true

### condition services

node_exporter: true

sshd: true

## see docker-compose folder for the services
docker:
  portainer:
    apps: https://github.com/jriguera/docker-portainer/raw/master/rpi/apps.json
  compose:
    name: system
    image: "jriguera/dockercompose"
    env:
      MYSQL_HOST: 'db.internal'
      MYSQL_ROOT_PASSWORD: 'root'

avahi:
  ifaces: eth0
  publish: true
  browsedomains: []
  publishdns:
  - 8.8.8.8

#bluetooth:
#  name: "RaspbianCloud Bluez"
#  discoverable_time: 300
#  pairable_time: 0
#  resolving: false
#  fast_connect: true
#  reconnect_uuids: []

#betterclone:
#  snapshots:
#    indexes: 6
#    keep: 1
#  backups:
#    keep:
#      initial: 1
#      daily: 7
#      weekly: 4
#      monthly: 6
#    rclone:
#      destination: /backups/raspi/data
#      id: GDrive
#      conf: |
#        type = drive
#        scope = drive
#        token = {"access_token":"blabla","expiry":"2018-10-28T12:17:43.881785294+01:00"}

#hostapd:
#  iface: wlan0
#  ssid: raspiwifi
#  passphrase: 'hola'
#  hidden: true
#  mode: g
#  channel: 6
#  hidden: true
#  wpa_mgmt: 'WPA-PSK'
#  country: NL
#  deny: []

#dhcp:
#  iface: wlan0
#  range: "10.1.1.10,10.1.1.100"
#  gw: 10.1.1.1
#  ntp:
#  - 10.1.1.1
#  dns:
#  - 10.1.1.1
#  domain: local
#  leasing: "24h"

#mail:
#  iface: lo
#  expire: 7d
#  alias:
#    root: 'root@gmail.com'
#    pi: 'pi@gmail.com'
#  relay:
#    server: 'mail.google.com:587'
#    sysuser: gmail
#    protocol: 'tls+auth'
#    auth:
```


If you decide to change the name of the raspberry pi, please also change  the `meta-data` 
file in the boot partition.

* Monit will run in *public-ip*:2812  (using the pi user and password to log in)
* Portainer will run in *public-ip*:9000 (first time it runs it will ask you to setup an
  admin user/password and a connection, just select **local** to manage the local docker on
  the raspberry pi).


# Author

Jose Riguera

