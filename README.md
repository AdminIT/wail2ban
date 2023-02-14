wail2ban
========

![Saddest Whale](http://i.imgur.com/NVlsY.png "Saddest Whale")

wail2ban is a windows port of the basic functionality of [fail2ban](http://www.fail2ban.org/), and combining elements of [ts_block](https://github.com/EvanAnderson/ts_block). 

This is modified version of Wail2ban by Miroslav Holman for use in AdminIT s.r.o company.
Readme file is modified version from original github project (https://github.com/glasnt/wail2ban)

Overview
--------

wail2ban is a system that takes incoming failed access events for a custom configurable set of known event ids, and given sufficient failed attacks in a period of time, creates temporary firewall rules to block access. 


Installation 
------------

Installing wail2ban is a case of a fiew simple tasks: 

 * copy all the repository files to a secure location (write permissions only for necessary user accounts recommended) on the client machine, e.g. `C:\Program Files\wail2ban`
 * Download latest version of nssm from their official website https://nssm.cc/download
 * Unzip the 64bit or 32bit version and paste the nssm.exe into nssm folder
 * Run  wail2ban_install_service.ps1 with parameter `-install` (or without any parameters). Note: The script needs to be run from install location of wail2ban! (location that you copied files in first step)
 * After installation is complete start the service.


Uninstallation 
------------
 * Run wail2ban_install_service.ps1 with parameter `-uninstall`


Command line execution
---------------------

wail2ban has `write-debug` things through it, just uncomment the `$DebugPreference` line to enable. This will output nice things to CMD, if running ad-hoc.

There are also a number of options that can be run against the script to control it: 
 
 * `-config` : dumps a parsed output of the configuration file to standard out, including timing and whitelist configurations. 
 * `-jail`   : shows the current set of banned IPs on the machine
 * `-jailbreak`: unbans every IP currently banned by the script. 
 * `-help` : See complete list of commands

Technical overview 
------------------

Event logs for various software packages are configured to produce messages when failed connections occur. The contents of the events usually contain an IP, an a message something along the lines of "This IP failed to connect to your server."

Typical examples of this include: 

 * Security Event ID 4625, "Windows Security Auditing". 
  * `An account failed to log in. ... Source Network Address: 11.22.33.44`

Database products also include these kind of events, such as: 

 * Application Event ID 18456, "Microsoft SQL Server".
  *  `Login failed for user 'sa'. Reason: Password did not match that for the login provided. [CLIENT: 11.22.33.44]`

These events are produced any time someone mistypes a password, or similar. 

The issue occurs when automated brute-force entry systems attempt to access systems multiple times a second. 

What wail2ban does
------------------

wail2ban is a real-time event sink for these messages. As messages come in, wail2ban takes note of the time of the attempt and the IP used in the attempt. Given enough attempts in a specific period of time, wail2ban will generate a firewall rule to block all access to the client machine for a certain period of time. 

In a default setup, if an IP attempts 5 failed passwords in a 2 minute period, they get banned from attempting again for a period of time.

How long? Well, that depends on how many times they've been banned before!

There is a file called BannnedIPLog.ini that will keep a count of how many times an IP has been banned. 

The punishment time is based on the function `y=5^x`, where x is the amount of times it has been banned, and y is the amount of minutes it's banned for. 

This allows for scaling of bans, but prevent permenant bans, which may cause issues in the future as IPs are reassigned around the blagosphere. 

There is also a `$MAX_BANDURATION` in place, which means that an IP cannot be banned for more than 3 months. Given the ban duration function gives values of years at the 10th increment, it's better to cap things out.

Failsafes 
---------

As with all automated systems, there can be some false-positives. 

**Whitelists** - this script can be configured with a whitelist of IPs that it will never ban, such as a company IP block. 

**Self-list** - the script automatically adds a set of IPs to the whitelist that it knows as not to ban, based on the configured static IPs on the host machine. That is, it will ignore attempts from itself (or event logs which list it's own IP in the message). 

**Timeouts** - IPs are only banned for specific period of time. After this time, they are removed from the firewall by the script. The timeouts are parsed once a new failed attempt is captured by the system. This may mean that IPs are unbanned after their exact unlock time, but for sufficiently attacked systems, this difference is not a major issue.

**Jailbreak** - a configuration called `-jailbreak` can be run against the script at any time to immediately remove all banned IPs. All their counters are reset, and it is as if the IP never tried to attack the machine.


Features added by AdminIT
--------
* Ban parameter - bans the specified IP permanently
* Option to ban whole IP ranges - Currently wail2ban can be switched into 2 modes of baning the CIDR masks. This is specified by parameter `-cidrmask 24` or `-cidrmask 16` of the wail2ban.ps1 script. If you installed wail2ban as service trough nssm, you'll have to use nssm.exe in gui mode in order to edit the lauch parameters

For additional info refer to `-help` command. Also full list of changes can be found in comments section of wail2ban.ps1 main script.

htmlgen
---------

I've added a script that will grep the wail2ban log file, and generate some nice statistics, and show the top banned IPs by country. 
[Sample Report](http://i.imgur.com/ufb9mvX.png)

If you want to enable this, grok the main wail2ban.ps1 script for the call to `wail2ban_htmlgen.ps1`, and enable it (remove the comment)


Limitations
-----------
* Wail2ban works only on Windows or Windows server from Windows server 2016 and up. This is due to a eventvwr bug present in earlier Windows version, that does not write incoming IP adress, which made the false audit, into event log, if the adress is not resolvable by local network hostname.
* Windows Firewall has to be turned ON on network profile you using! Wail2ban is just simply creating and removing Windows Firewall rules in order to block incoming requests.

Update 2020: There have been several on and off repo communications saying this code is still useful! I don't have any way to test the following, but hopefully the following may help: 
 
 * Thanks to Marco Jonas, `BLOCK_TYPE` is set to `netsh`, which I presume still exists.
 * Thanks to Gl0, you can add SSL RDP Login support with [this patch](https://github.com/glasnt/wail2ban/pull/13/files)
