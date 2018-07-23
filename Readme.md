# Raspbian Cloud

Goal: build an core base image for Raspberry Pi with boot auto-configuration. 
Add-on services in docker.

* Cloud-init support on vfat (/boot) partition
* Docker and docker-compose with auto update (systemd service) and configuration in `/boot/docker-compose` folder
* Monit control for main services (Docker, Dnsmasq, Prometheus exporter, Opensmtpd, OpenSSH, ...)
* Dnsmasq for caching and dns control
* Prometheus node-exporter
* Opensmtpd pre-setup with local mail delivery
* Openssh
* Rng-tool
* Pure systemd setup (no sysvinit folder)
  * rsyslog disabled
  * systemd-crom
  * no sysvinit folder

