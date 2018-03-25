#!/bin/bash

# COMPATIBILITY: CentOS 6.x

# Sets up the yum repos for CentOS 6

# SOURCE THE 'get-os.sh' SCRIPT TO GET OS AND VERSION
. ./incl/get-os.sh

# UBUNTU WILL WORK WITH JUST THIS BIT
if [[ $OS == "deb" ]] ; then
	apt-get update
	echo "Run \"apt-get dist-upgrade -y\" now to update system,
run ./fw-rules.sh -i 22,
and then reboot the box."
	exit
fi

# DETERMINE THE NAME OF THE REPO ARCHIVE
if [[ $OS == "cent" ]] && [[ $VER == 6 ]] ; then
	ARCH=repos-CentOS6.tar.bz2
elif [[ $OS == "cent" ]] && [[ $VER == 7 ]] ; then
  ARCH=repos-CentOS7.tar.bz2
fi

printf "Extracting archive..."
tar -xvf $ARCH > /dev/null 2>&1
if [[ $? -eq 0 ]] ; then
  printf "success\n"
else
  printf "failed - cannot continue\n"
  exit
fi

printf "Moving repo files into place..."

mv yum.repos.d/*.repo /etc/yum.repos.d/

if [[ $? -eq 0 ]] ; then
  printf "success\n"
else
  printf "failed - cannot continue\n"
  exit
fi

printf "Moving rpm gpg keys into place..."

mv rpm-gpg/* /etc/pki/rpm-gpg/
if [[ $? -eq 0 ]] ; then
  printf "success\n"
else
  printf "failed - cannot continue\n"
  exit
fi

printf "Importing rpm gpg keys..."

rpm --import /etc/pki/rpm-gpg/*
if [[ $? -eq 0 ]] ; then
  printf "success\n"
else
  printf "failed\n"
fi

printf "Cleaning rpm info..."

yum clean all
if [[ $? -eq 0 ]] ; then
  printf "success\n"
else
  printf "failed\n"
fi

printf "Retrieving package information..."
yum makecache

echo "Cleaning up leftover directories..."
rm -rf yum.repos.d
rm -rf rpm-gpg

echo "Run \"yum -y update\" now to update packages,
then run ./fw-rules.sh -i 22
and then reboot the box."
