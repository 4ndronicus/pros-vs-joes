# At the Event #

## Strategy Checklist ##
At the Pros vs Joes exercise, we'll want to do several things.  I am keeping a running list of things below.  Please put in additional ideas.

 * Set up static ARP tables to mitigate man-in-the-middle attacks
 * Set up /etc/hosts files to mitigate DNS hijacking
 * make note of what is running, make sure it is enabled in systemctl
 * Install needed packages such as htop
 * Check /etc/rc.local for any nefarious stuff
 * Change and log passwords for system users
 * Install additional packages, download scripts like lynis, rkhunter, rootck
 * Check any NFS exports and configs
 * Run lynis, rkhunter, rootck, etc
 * Remove compilers
 * Check for any additional administrative accounts
 * Check for users in administrative groups that shouldn't be there
 * Look for files modified less than a day ago in any webroots (nginx, apache, etc)
 * Remove users that are not needed
 * A way to implement static ARP tables
 * Remove all users from wheel and root groups except for root and hackmasters user
 * Look at the different services and research best practices for those services
 * Research known vulnerabilities for services and web apps that are running, and how to fix them
 * Periodic checks of ~/.ssh/authorized_keys on all of the boxes so we know that we only have our own

## Package Checklist ##
There might be some packages that will be helpful to get installed on the servers.  Below is a list of the ones we'd like installed.  Feel free to add to it.
We probably do *NOT* want nmap on the servers.

 * bind-utils
 * net-tools
 * vim
 * bzip2

# Linux Prep Scripts #

## Overview ##

It seems like it will be most beneficial to get into the boxes and get them locked down as quickly as possible, followed by updating the system packages.  To help with this, I have created a series of scripts.  Please look through them, get familiar with them, and if there are any suggestions, let's work together to make them as solid as possible.

## Details ##

The scripts now work with the following OSes:

 * CentOS 6.x
 * CentOS 7.x
 * Ubuntu Server 17.10
 * Ubuntu Server 16.04
 * Ubuntu Server 14.04

You should be able to clone this repo and copy the scripts to a VM running any of these.  The scripts should run without errors.  If you find that there are problems, please let me know.

### ssh-user.sh ###
The first thing we want to do is make a user that is the only one who can log into the box.  We can then use this account to log in.  Also, we are going to only use SSH public and private keys to give us access.  So when you log into the box the first time, the first script we'll run is called 'ssh-user.sh'.  If you take a look, you'll see that this script creates the user, called 'hackmasters', and adds that user to the 'wheel' group.  Then, it creates the '/home/hackmasters/.ssh' folder where the public keys are stored.  It then goes through each of our keys, adding them to the '/home/hackmasters/.ssh/authorized_keys' file so we can get in as the 'hackmasters' user.  Next, the script sets appropriate permssions and ownership on the file and its containing folder.  Finally, it will prompt you to change the password for the 'hackmasters' user.  When you do, you'll need to document it in the Google Spreadsheet that will be shared with everyone on our team.  This ensures that we all know what passwords have been set on which systems.

### harden-ssh.sh ###
The next thing we want to do is to harden the ssh daemon.  This script, called 'harden-ssh.sh', ensures that the previous step has been run and that the 'hackmasters' user has been created.  It then goes through the '/etc/ssh/sshd_config' file and applies the settings as listed at the bottom of the script.  We're essentially setting it up with known secure settings for the ssh daemon.  Things like turning password authentication off, forcing the protocol to version 2, disallowing the root user from logging in, turning on public key authentication, and setting 'hackmasters' as the only user allowed to log into the system.

### fw-setup.sh ###
Next, we want to get the firewall set up.  The first step in doing this is that we need to make sure the proper daemon is installed and running.  This is what 'fw-setup.sh' does.  If 'firewalld' is installed, the script shuts it down and uninstalls it.  It then ensures that 'iptables' is installed along with the package that controls the service.  It will also set iptables to run on system boot, and then starts up the iptables service in preparation for the next script.

### fw-rules.sh ###
This script is responsible for quick and easy control of the firewall rules.  bashNinja was awesome enough to make it possible to pass commandline arguments to this script.  It's fairly well-documented, if you take a look at it.  The basic premise is that it will set up the firewall with default deny on everything except for inbound connections on port 22.  When you first run it, you'll need to allow ports 80 and 443 outbound.  This is so that yum can go out and pull down the packages for the system update.  I'll show you how this is done below.  This script also saves the firewall rules so that they can be loaded up on next system boot.

### set-up-repos.sh ###
Finally, we need to make sure we have the latest packages available for patching the systems.  This is done through the package repositories.  The 'set-up-repos.sh' script extracts an archive with these repos in it.  It then places them in '/etc/yum.repos.d/'.  It also moves and imports the signature keys for these repos so that our systems will trust them.  Then, it clears the rpm data and refreshes it so that we can perform an update of the system packages.

## Lab ##

Now that I've explained the scripts and what they do, I'd like to give everyone a chance to run through and use them.

### CentOS 6 ###
If you're running these on CentOS 6, we'll have you download the latest minimal install ISO from here:
<http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1708.iso>

### CentOS 7 ###
If you're running these on CentOS 7, we'll have you download the latest minimal install ISO from here:
<http://mirrors.umflint.edu/CentOS/6.9/isos/x86_64/CentOS-6.9-x86_64-minimal.iso>

### Ubuntu 16.04 and 17.10 ###
Download from here:
<https://www.ubuntu.com/download/server>

### Ubuntu 14.04 ###
<https://drive.google.com/file/d/1Rkl5z4f0jGucoXJuXqt_PsR_Mq27FIGf/view?usp=sharing>

### VM Setup ###

If you have downloaded the Ubuntu 14.04, import the OVA into your hypervisor and fire it up.

If you downloaded an ISO, you'll need to use it to install Linux onto some system.  This can be a physical system or VM.  As there are quite a few ways to do this, I'll assume that you already know how to do it or that you can look it up on Google or Youtube.  If you run into trouble with this step, let me know.  Here are a few guidelines, though:

1. Do not create a user other than root.
2. If using a VM, set the NIC to be in 'Bridged' mode.

### Copy Scripts ###

Once you are done installing your OS, you'll scp the appropriate script bundle over to it.  SSH into the new system.  As bzip2 will not be installed (it's a minimal install), you'll need to install that package.  You'll also need telnet for a later step, so we'll install that here, too:

`# yum -y install bzip2 telnet`

Then, extract the archive:

`# tar -xvf CentOS7.tar.bz21`

You should now be looking at a directory with the scripts listed above in it, along with our public SSH keys.  If you don't see your key listed there, that means I don't have it.  Email it to me at smmorris@gmail.com so I can get it in there.

### SSH User ###

First, just execute the 'ssh-user.sh' script:

`# ./ssh-user.sh`

Notice where it prompts you to change the password, and instructs you to document it.  This will be critical at Pros vs Joes.  Its output will look like this:

`# ./ssh-user.sh 
Adding user: hackmasters...success
Adding user to 'wheel' group...success
Creating ssh directory...success
Adding keys...
Adding key and-key.pub...success
Finalizing...
Changing password for user hackmasters.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.
NOW, DOCUMENT THAT PASSWORD!
#`

Note:  You will have to add your own SSH public key to /home/hackmasters/.ssh/authorized_keys.  Generate it on your own box if you don't have one.  Again, I'll have to assume that you already know how to do this, or can research it on Google.  It's a fairly common process, and is well-documented.  Copy it over to the Cent box.  Add it to the /home/hackmasters/.ssh/authorized_keys file.  If you have questions on this step, let me know.  If you do not do this, you won't be able to get back into the box!

### Harden SSH ###

Next, run 'harden-ssh.sh'.  The output should look like this:

`# ./harden-ssh.sh 
Checking for user 'hackmasters'...found
Setting GSSAPIAuthentication to no.....success
Setting PasswordAuthentication to no.....success
Setting X11Forwarding to no.....success
Setting Protocol to 2.....success
Setting PermitRootLogin to no.....success
Setting PubkeyAuthentication to yes.....success
Setting AuthorizedKeysFile to .ssh/authorized_keys.....success
Setting AllowUsers to hackmasters.....success
Restarting SSH for changes to take effect
#`

### Firewall Setup ###

Then, run 'fw-setup.sh' to get the firewall installed and running. It might look something like this:

`# ./fw-setup.sh 
Checking whether 'firewalld' is installed... found!
Checking whether 'iptables' is installed... found!
Checking whether 'iptables-services' is installed... not found.
Disabling firewalld... success!
Removing firewalld... success!
Installing iptables-services... success!
Enabling iptables on boot... success!
Starting iptables... success!
#`

### Firewall Rules ###

Now, we have to set up the firewall rules.  To do this, run 'fw-rules.sh' to allow outbound connections to ports 80 and 443:

`# ./fw-rules.sh -o 80,443
Enabling SSH IN by default. You'll have to manually disable this.
Allow output on port 80.
Allow output on port 443.
Enabling DNS OUT by default. You'll have to manually disable this.
Allowing Loopback.
Saving to IPTables
iptables: Saving firewall rules to /etc/sysconfig/iptables:[  OK  ]
#`

### Repository Setup ###

Now, we'll set up the repositories with the 'set-up-repos.sh' script. CentOS looks like this:

`# ./set-up-repos.sh 
Extracting archive...rpm-gpg/
rpm-gpg/RPM-GPG-KEY-CentOS-7
rpm-gpg/RPM-GPG-KEY-CentOS-Debug-7
rpm-gpg/RPM-GPG-KEY-CentOS-Testing-7
rpm-gpg/RPM-GPG-KEY-EPEL-7
yum.repos.d/
yum.repos.d/elrepo.repo`

`... lots more output ...`

` base: mirrordenver.fdcservers.net
 elrepo: elrepo.org
 epel: mirrors.syringanetworks.net
 extras: mirror.den1.denvercolo.net
 ius: mirrors.kernel.org
 remi-safe: mirrors.mediatemple.net
 rpmfusion-free-updates: mirror.math.princeton.edu
 rpmfusion-nonfree-updates: mirror.math.princeton.edu
 updates: mirror.web-ster.com`

`Metadata Cache Created
Cleaning up leftover directories...
Run "yum -y update" now to update packages, and then reboot the box.
#`

### Update Packages ###

For CentOS, we'll run "yum -y update" to update the packages on the box:

`# yum -y update
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile`

` base: mirrordenver.fdcservers.net
 elrepo: elrepo.org
 epel: mirrors.syringanetworks.net
 extras: mirror.den1.denvercolo.net
 ius: mirrors.kernel.org
 remi-safe: mirrors.mediatemple.net
 rpmfusion-free-updates: mirror.math.princeton.edu
 rpmfusion-nonfree-updates: mirror.math.princeton.edu
 updates: mirror.web-ster.com`

`Resolving Dependencies
--> Running transaction check`

`... lots more output ...`

`  systemd.x86_64 0:219-42.el7_4.10
  systemd-libs.x86_64 0:219-42.el7_4.10
  systemd-sysv.x86_64 0:219-42.el7_4.10
  teamd.x86_64 0:1.25-6.el7_4.3
  tuned.noarch 0:2.8.0-5.el7_4.2
  tzdata.noarch 0:2018c-1.el7
  util-linux.x86_64 0:2.23.2-43.el7_4.2
  wpa_supplicant.x86_64 1:2.6-5.el7_4.1
  yum.noarch 0:3.4.3-154.el7.centos.1`

`Replaced:
  grub2.x86_64 1:2.02-0.64.el7.centos             grub2-tools.x86_64 1:2.02-0.64.el7.centos`        

`Complete!
#`

For Ubuntu, we'll run 'apt-get dist-upgrade -y' to update the system.

### Close 80 and 443 Outbound ###

Now, we need to close ports 80 and 443 outbound.  We do this by only specifying the one rule we need, port 22 inbound.  Everything else is blocked by default:

`# ./fw-rules.sh -i 22
Allow input on port 22.
Enabling SSH IN by default. You'll have to manually disable this.
Enabling DNS OUT by default. You'll have to manually disable this.
Allowing Loopback.
Saving to IPTables
iptables: Saving firewall rules to /etc/sysconfig/iptables:[  OK  ]
#`

If you want to make sure that 80 and 443 are closed, try to telnet to port 80 or 443 on a known web server.  It should not connect.  You should see this:

`# telnet google.com 80
Trying 172.217.11.174...
^C
#`

You'll have to CTRL+C to exit.

You should not see this:

`# telnet google.com 80
Trying 172.217.11.174...
Connected to google.com.
Escape character is '^]'.`

If you see the latter, check that you have run the 'fw-rules.sh' script exactly as shown above.

### Reboot ###

Now, we'll reboot the box:

`# reboot`

### Log Back In ###

Then, to make sure everything went smoothly, you'll want to log back into the system using the 'hackmasters' user:

`$ ssh hackmasters@<ip of linux box>`

Once you are in, become root with:

`$ sudo su -`

`We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:`

`    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.`

`[sudo] password for hackmasters: 
Last login: Sat Mar 17 00:22:45 MDT 2018 from 10.0.10.18 on pts/0
#`

Once you see this, the basic system hardening is done, and you are back in the box with the correct user, and that user can become root.

## Conclusion of Lab ##

If you run one command after the next, this entire process will take less than 5 minutes, most of that being updating the packages.  If you hit any snags, or one of the scripts errors out, let me know.  Let's get these scripts running smoothly.

## Additional Information ##

I'll be working on versions for RHEL 6/7, OpenSuSE, Debian, Fedora, etc as I have time.  For now, go through this process with the scripts that are there.  I've run through it several times myself.  But let's all get familiar with it.
