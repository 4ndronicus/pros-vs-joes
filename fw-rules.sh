#!/bin/bash
#
# BSidesSLC 2018 Joes vs Pros iptables script
#
# The approach here is to drop all packets by default.
# Then, we explicitly allow the traffic that we want.
# The catch, of course, is to allow it in both the
# INPUT and OUTPUT chains.  Otherwise, it will not work.
#
# This approach ensures that no reverse shells will work.
# It also ensures that we have open only exactly what we need.
#
# We cannot block access by the red team using firewall rules.
# However, we can block any processes (like beacons) that they
# may create.  Any outbound connections not explicitly allowed
# by these rules will not work.
#
# In a production environment, you'd have rules explicitly 
# allowing or disallowing specific subnets or ip ranges.
# However, because of the nature of the game, we cannot block 
# red teamers using firewall rules.

# Common Ports
# ------------------------------------
# FTP:              21, 20 
# SAMBA:            139, 445, 137, 138 
# VNC:              5900
# POSTGRES:         5432
# MYSQL:            3306
# HTTP:             80
# HTTPS:            443
# POP3:             110
# SMTP:             25, 465
# IMAP:             143, 993
# SSH:              22

# FOR YUM TO CONNECT OUT FOR UPDATES, WE'LL NEED OUTBOUND 80/443 CONNECTIONS
# AFTER UPDATING, WE SHOULD CLOSE THESE BACK UP

usage() { echo -e "usage: $0 [-h]

arguments:
  -h
    show this help message and exit
  -i <integer list>
    allow TCP ports inbound. Accepts integer lists comma seperated.
    Example: -i 22,80,443
  -o <integer list>
    allow TCP ports outbound. Accepts integer lists comma seperated.
    Example: -o 22,80,443
  -u <integer list>
    allow UDP ports inbound. Accepts integer lists comma seperated.
    Example: -u 22,80,443
  -d <integer list>
    allow UDP ports outbound. Accepts integer lists comma seperated.
    Example: -d 22,80,443" 1>&2;
  exit 1;
}

# SOURCE THE 'get-os.sh' SCRIPT TO GET OS AND VERSION
. ./incl/get-os.sh

re='^([0-9]+(,[0-9]+)*)?$'

while getopts ":i:o:p:u:d:" z; do
    case "${z}" in
        i)
            i=${OPTARG}
            if ! [[ $i =~ $re ]] ; then usage; fi
            ;;
        o)
            o=${OPTARG}
            ;;
        u)
            u=${OPTARG}
            ;;
        d)
            d=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
if [ $OPTIND -eq 1 ]; then usage; fi
shift $((OPTIND-1))

IPTABLES=/sbin/iptables

$IPTABLES -F

# SET TO DEFAULT DROP ON THESE CHAINS
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP

# REJECT PACKETS WITH INVALID STATES
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,SYN FIN,SYN -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags PSH,ACK PSH -j REJECT
$IPTABLES -A INPUT -p tcp --tcp-flags ACK,URG URG -j REJECT

echo "-----------------------------------------------------------------"
# Do TCP Input
if ! [ -z "${i}" ]; then
    for x in ${i//,/ }
    do
        $IPTABLES -A INPUT -p tcp --dport $x -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPTABLES -A OUTPUT -p tcp --sport $x -m state --state ESTABLISHED -j ACCEPT
        echo "Allow INPUT on port ${x}/tcp."
    done
fi

# Do UDP Input
if ! [ -z "${u}" ]; then
    for x in ${u//,/ }
    do
        $IPTABLES -A INPUT -p udp --dport $x -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPTABLES -A OUTPUT -p udp --sport $x -m state --state ESTABLISHED -j ACCEPT
        echo "Allow INPUT on port ${x}/udp."
    done
fi

# Do TCP Output
if ! [ -z "${o}" ]; then
    for x in ${o//,/ }
    do
        $IPTABLES -A OUTPUT -p tcp --dport $x -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPTABLES -A INPUT -p tcp --sport $x -m state --state ESTABLISHED -j ACCEPT
        echo "Allow OUTPUT on port ${x}/tcp."
    done
fi

# Do UDP Output
if ! [ -z "${d}" ]; then
    for x in ${d//,/ }
    do
        $IPTABLES -A OUTPUT -p udp --dport $x -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPTABLES -A INPUT -p udp --sport $x -m state --state ESTABLISHED -j ACCEPT
        echo "Allow OUTPUT on port ${x}/udp."
    done
fi

echo "-----------------------------------------------------------------"

echo "Enabling SSH IN by default. You'll have to manually disable this."
# ALLOW INBOUND SSH CONNECTIONS
# NOTE: THIS DOES NOT ALLOW OUTBOUND SSH CONNECTIONS!
# ######### DO NOT COMMENT THIS ONE OUT OR YOU WILL BE LOCKED OUT OF THIS HOST ##########
$IPTABLES -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT


echo "Enabling DNS OUT by default. You'll have to manually disable this."
# OUTBOUND DNS LOOKUPS
$IPTABLES -A OUTPUT -p udp --dport 53 -j ACCEPT
$IPTABLES -A INPUT -p udp --sport 53 -j ACCEPT

# ALLOW PING
echo "Allowing PING."
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

echo "Allowing Loopback."
# ALLOW LOOPBACK
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# BASED ON WHICH OS WE ARE USING, SAVE THE IPTABLES RULES
echo "Saving to IPTables"
case $OS in
	"cent"*)
		service iptables save
		;;
	"deb"*)
		iptables-save > /etc/iptables/rules.v4
		grep -iv iptables-restore /etc/rc.local > /tmp/rc.local
		mv -f /tmp/rc.local /etc/rc.local
		echo "/sbin/iptables-restore < /etc/iptables/rules.v4" >> /etc/rc.local
		;;
	*)
		;;
esac
