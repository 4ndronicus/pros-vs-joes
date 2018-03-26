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