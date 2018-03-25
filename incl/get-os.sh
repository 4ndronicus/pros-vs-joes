#!/bin/bash

if [[ -e /etc/redhat-release ]] && [[ `grep -i "centos release 6"  /etc/redhat-release | wc -l` -ne 0 ]] ; then
	OS="cent"
	VER=6
fi

if [[ -e /etc/redhat-release ]] && [[ `grep -i "CentOS Linux release 7"  /etc/redhat-release | wc -l` -ne 0 ]] ; then
	OS="cent"
	VER=7
fi

# This is true of Ubuntu Server 14, 16, and 17
if [[ -e /etc/debian_version ]] && [[ `grep -i "/sid"  /etc/debian_version | wc -l` -ne 0 ]] ; then
	OS="deb"
fi
