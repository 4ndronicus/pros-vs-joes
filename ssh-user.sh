#!/bin/bash

# COMPATIBILITY: CENTOS 6.x/7.x

# Adds a user and puts public keys in place for that user

USER=hackmasters
DIR=/home/${USER}/.ssh

# SOURCE THE 'get-os.sh' SCRIPT TO GET THE OS AND VERSION
. ./incl/get-os.sh


# FOR UBUNTU, SUDO GROUP IS 'sudo'
# FOR CENTOS, SUDO GROUP IS 'wheel'
case $OS in
  "cent"*)
    GROUP="wheel"
    ;;
  "deb"*)
    GROUP="sudo"
    ;;
  *)
    ;;
esac

printf "Adding user: ${USER}..."
useradd hackmasters
if [[ $? -eq 0 ]]; then
  printf "success\n"
else
  printf "failed - cannot continue\n"
  exit
fi

printf "Adding user to '${GROUP}' group..."
usermod -aG ${GROUP} hackmasters

if [[ $? -eq 0 ]]; then
  printf "success\n"
else
  printf "failed - cannot continue\n"
  exit
fi

# ONLY NEEDS TO BE DONE ON CENTOS 6
if [[ $OS == "cent" ]] && [[ $VER == 6 ]]; then
	echo "Configuring sudoers file..."
	grep -iv wheel /etc/sudoers > /tmp/sudoers
	mv -f /tmp/sudoers /etc/sudoers
	echo "%wheel  ALL=(ALL)  ALL" >> /etc/sudoers
fi

printf "Creating ssh directory..."
mkdir -p ${DIR}
if [[ $? -eq 0 ]]; then
  printf "success\n"
else
  printf "failed - cannot continue\n"
  exit
fi

printf "Adding keys...\n"
for i in `ls -1 *.pub` ; do
  printf "Adding key ${i}..."
  cat ${i} >> ${DIR}/authorized_keys
  if [[ $? -eq 0 ]]; then
    printf "success\n"
  else
    printf "failed\n"
  fi
done

echo "Finalizing..."

chown -R ${USER}.${USER} ${DIR}
chmod 0700 ${DIR}
chmod 0600 ${DIR}/authorized_keys

passwd ${USER}

echo "****************************************"
echo -e "\e[1;40;31mNOW, DOCUMENT THAT PASSWORD!\e[0m"
echo "Also, next, you'll run ./harden-ssh.sh"
echo "****************************************"

