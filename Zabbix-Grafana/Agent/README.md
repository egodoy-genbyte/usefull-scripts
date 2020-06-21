# Deply Zabbix Agent

## Windows

This script updates or deply the Agent. You must have a shared folder with:

* __.exe files__ for the agent on root
* __.conf file__ in root. It must have all basic configuration needed and the swit will replace the line with "Hostline=ServerName"
* __conf.d folder__ with all specific config files (needed by templates)
* __Script folder__ with ell the neew and updated scripts

### .conf file

I assume that you have a functional .conf file, and that you use folders for extra config lines and script. This is my example, in which I uso TLSK encription:

```bash
LogType=system
Server=10.10.10.1
ServerActive=10.10.10.1
Hostname=Server
EnableRemoteCommands=1
UnsafeUserParameters=1
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=Identidad
TLSPSKFile=C:\Program Files\Zabbix Agent\psk.key
Timeout=15

Include=C:\Program Files\Zabbix Agent\conf.d\*.conf
```

As you can note in the config example, I use a folder named __conf.d__ for store extra configuration (like commands and performance counter for specific templates) 

## :notebook: Next Steps

In nex versions, I would like to incluye:

* Check if host ins in Zabbix
* If it's in Zabbix, Disable during the update
* If isn't in Zabbix, Create the host