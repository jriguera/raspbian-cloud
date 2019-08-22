Please define the configuration settings for the Raspberry Pi in the
file `parameters.yml`. Those values will be used in the templates to
render the configuration files for each service.

The folders defined here contain those template files which will be
processed by https://github.com/jriguera/confinit at every boot. There
are two processing units:

1. At early boot (just after the local fs are mounted)
2. At the end of the startup process, before docker-compose

Each unit has its own configuration file.
