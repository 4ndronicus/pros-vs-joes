#!/bin/bash

# COMPATIBILITY: CENTOS 6.x

# Removes firewalld and installs iptables

# SOURCE THE 'get-os.sh' SCRIPT TO GET THE OS AND VERSION
. ./incl/get-os.sh

# Check whether firewalld is installed
FWD=0
printf "Checking whether 'firewalld' is installed... "
if [[ $OS == "cent" ]] ; then
	rpm -qa | grep -i firewalld | grep -iv filesystem > /dev/null 2>&1
elif [[ $OS == "deb" ]] ; then
	dpkg -l | grep -i firewalld | grep -iv filesystem > /dev/null 2>&1
fi
if [[ $? -ne 0 ]]; then
  printf "not found.\n"
else
  printf "found!\n"
  FWD=1
fi

# Check whether iptables is installed
IPT=0
printf "Checking whether 'iptables' is installed... "
if [[ $OS == "cent" ]] ; then
	rpm -qa | grep -i iptables | grep -iv services > /dev/null 2>&1
elif [[ $OS == "deb" ]] ; then
	dpkg -l | grep -i iptables | grep -iv services > /dev/null 2>&1
fi
if [[ $? -ne 0 ]]; then
  printf "not found.\n"
else
  printf "found!\n"
  IPT=1
fi

# CENTOS 7 NEEDS iptables-service
if [[ $OS == "cent" ]] && [[ $VER -eq 7 ]]; then
	# Check whether iptables-services is installed.  This is what controls
	# the iptables service.
	IPTS=0
	printf "Checking whether 'iptables-services' is installed... "
	rpm -qa | grep -i iptables-services > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		printf "not found.\n"
	else
		printf "found!\n"
		IPTS=1
	fi
fi

# UBUNTU 17 NEEDS iptables-persistent
if [[ $OS == "deb" ]] ; then
	# Check whether iptables-persistent is installed
	IPTP=0
	printf "Checking whether 'iptables-persistent' is installed... "
	dpkg -l | grep -i iptables-persistent > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
	  printf "not found.\n"
	else
	  printf "found!\n"
	  IPTP=1
	fi
fi

# If we found firewalld, disable it and uninstall it
if [[ $FWD -eq 1 ]] ; then

	# ONLY DO THIS ON CENT - UBUNTU DOESN'T NEED THIS TO WORK
	if [[ $OS == "cent" ]] ; then

		printf "Disabling firewalld... "

		# FOR CENTOS 6, DO THIS
		if [[ $VER -eq 6 ]]; then

			chkconfig --del firewalld > /dev/null 2>&1

		# FOR CENTOS 7, DO THIS
		elif [[ $VER -eq 7 ]]; then

			systemctl disable firewalld > /dev/null 2>&1

		fi

		if [[ $? -eq 0 ]]; then
		  printf "success!\n"
		else
		  printf "failed!\n"
		fi
	fi

	printf "Removing firewalld... "

	if [[ $OS == "cent" ]] ; then
		yum -y erase firewalld > /dev/null 2>&1
	elif [[ $OS == "deb" ]] ; then
		apt-get -y remove firewalld > /dev/null 2>&1
	fi

	if [[ $? -eq 0 ]]; then
	  printf "success!\n"
	else
	  printf "failed!\n"
	fi
fi

# If iptables was not found, make sure it's installed.
if [[ $IPT -eq 0 ]] ; then

	printf "Installing iptables... "
	if [[ $OS == "cent" ]] ; then
		yum -y install iptables > /dev/null 2>&1
	elif [[ $OS == "deb" ]] ; then
		apt-get -y  install iptables > /dev/null 2>&1
	fi
	if [[ $? -eq 0 ]]; then
	  printf "success!\n"
	else
	  printf "failed!\n"
	fi

	IPT=1
fi

# ONLY REQUIRED BY CENTOS 7
# If iptables-service was not found, make sure it's installed
if [[ $IPTS -eq 0 ]] && [[ $OS == "cent" ]] && [[ $VER -eq 7 ]] ; then

	printf "Installing iptables-services... "
	yum -y install iptables-services > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
	  printf "success!\n"
	else
	  printf "failed!\n"
	fi

	IPT=1
fi

# UBUNTU 17 REQUIRES THIS, NOTHING ELSE DOES
if [[ $OS == "deb" ]] ; then
	# If iptables-persistent was not found, make sure it's installed.
	if [[ $IPTP -eq 0 ]] ; then
		printf "Installing iptables-persistent... "
		apt-get -y  install iptables-persistent
		if [[ $? -eq 0 ]]; then
		  printf "success!\n"
		else
		  printf "failed!\n"
		fi
	fi
fi

# UBUNTU DOESN'T NEED ANY OF THIS
if [[ $OS == "cent" ]] ; then

	# Enable iptables to run on boot
	printf "Enabling iptables on boot... "

	if [[ $OS == "cent" ]] && [[ $VER -eq 6 ]]; then

		chkconfig --add iptables > /dev/null 2>&1

	elif [[ $OS == "cent" ]] && [[ $VER -eq 7 ]]; then

		systemctl enable iptables > /dev/null 2>&1

	fi

	if [[ $? -eq 0 ]]; then
	  printf "success!\n"
	else
	  printf "failed!\n"
	fi

	# Start the iptables service
	printf "Starting iptables... "

	if [[ $OS == "cent" ]] && [[ $VER -eq 6 ]]; then

		service iptables start > /dev/null 2>&1

	elif [[ $OS == "cent" ]] && [[ $VER -eq 7 ]]; then

		systemctl start iptables > /dev/null 2>&1

	fi

	if [[ $? -eq 0 ]]; then
	  printf "success!\n"
	else
	  printf "failed!\n"
	fi

fi

echo "****************************************************************************"
echo "The next thing to do is lock down the firewall and open only the ports that
need to be opened.  Take a look at the scans.  Determine what needs to be open for
the scorebot to connect. Run ./fw-rules.sh with the appropriate options, or with
'-h' to get usage instructions."
echo "****************************************************************************"
