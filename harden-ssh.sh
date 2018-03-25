#!/bin/bash

# Hardens the ssh daemon with known secure settings - restarts ssh

FILE=sshd_config
FPATH=/etc/ssh/${FILE}

# SOURCE THE 'get-os.sh' SCRIPT TO GET THE OS AND VERSION
. ./incl/get-os.sh

# Sets a directive in the sshd config file to the desired value
function setVal(){

  DIRECTIVE=$1
  VALUE=$2

  printf "Setting ${DIRECTIVE} to ${VALUE}..."

  # Strip out whatever's in there now - put into tmp file
  grep -iv $DIRECTIVE ${FPATH} >> /tmp/${FILE}

  if [[ $? -eq 0 ]]; then
    printf "."
  else
    printf "failed - cannot continue\n"
    exit
  fi

  # Move it back into place
  mv -f /tmp/${FILE} ${FPATH}

  if [[ $? -eq 0 ]]; then
    printf "."
  else
    printf "failed - cannot continue\n"
    exit
  fi

  # Add the directive with desired value back into the file - appends to the end
  echo "${DIRECTIVE} ${VALUE}" >> ${FPATH}

  if [[ $? -eq 0 ]]; then
    printf "success\n"
  else
    printf "failed - cannot continue\n"
    exit
  fi
}

printf "Checking for user 'hackmasters'..."
grep -i hackmasters /etc/passwd > /dev/null 2>&1
if [[ $? -ne 0 ]] ; then
  echo $?
  printf "User does not exist! Run ssh-user.sh first!\n"
  exit
else
  printf "found\n"
fi

setVal GSSAPIAuthentication no
setVal PasswordAuthentication no
setVal X11Forwarding no
setVal Protocol 2
setVal PermitRootLogin no
setVal PubkeyAuthentication yes
setVal AuthorizedKeysFile  .ssh/authorized_keys
setVal AllowUsers hackmasters

echo "Restarting SSH for changes to take effect"

if [[ $OS == "cent" ]] && [[ $VER -eq 6 ]] ; then
	service sshd restart
elif [[ $OS == "cent" ]] && [[ $VER -eq 7 ]] ; then
	systemctl restart sshd
elif [[ $OS == "deb" ]] ; then
	/etc/init.d/ssh restart
fi

echo "****************************************"
echo "Next, you'll run ./fw-setup.sh"
echo "****************************************"
