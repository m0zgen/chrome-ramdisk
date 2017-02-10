#!/bin/bash
# # Chrome ramdisk
#
# ---------------------------------------------------------- VARIABLES #
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
# Determine script location
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
# Script name
me=`basename "$0"`

USR=$1

if [[ -z $USR ]]; then
  echo "Please use script - script username. CD script folder and run as sudo."
  exit 1
fi

if [[ ! -d /home/$USR/.chrome/ramdisk ]]; then
  echo "Not exist"
  mkdir -p /home/$USR/.chrome/ramdisk/Default/
  cd /home/$USR/.chrome/ramdisk
  mkdir cache config
  ln -s /home/$USR/.config/google-chrome config
  ln -s /home/$USR/.cache/google-chrome cache
  tar -cpf ramdisk.tar ramdisk/*
fi

if [[ ! -d /home/$USR/bin ]]; then
  mkdir /home/$USR/bin
  cp $SCRIPT_PATH/chrome-ramdisk /home/$USR/bin/
  chmod +x /home/$USR/bin/chrome-ramdisk
else
  cp $SCRIPT_PATH/chrome-ramdisk /home/$USR/bin/
  chmod +x /home/$USR/bin/chrome-ramdisk
fi

if [[ ! -d /etc/opt/chrome/policies/managed/ ]]; then
  mkdir -p /etc/opt/chrome/policies/managed
  cp $SCRIPT_PATH/cache-size.json /etc/opt/chrome/policies/managed/
else
  cp $SCRIPT_PATH/cache-size.json /etc/opt/chrome/policies/managed/
fi

if [[ ! -f /etc/systemd/system/chrome-ramdisk.service ]]; then
  cp $SCRIPT_PATH/chrome-ramdisk.service /etc/systemd/system/chrome-ramdisk-$USR.service
else
  cp $SCRIPT_PATH/chrome-ramdisk.service /etc/systemd/system/chrome-ramdisk-$USR.service
fi

echo "tmpfs /home/$USR/.chrome/ramdisk tmpfs noatime,nodiratime,nodev,nosuid,uid=1000,gid=1000,mode=0700,size=300M 0 0" >> /etc/fstab

sed -i "s/USR/$USR/g" /etc/systemd/system/chrome-ramdisk-$USR.service
sed -i "s/USR/$USR/g" /etc/opt/chrome/policies/managed/cache-size.json
sed -i "s/USR/$USR/g" /home/$USR/bin/chrome-ramdisk

chown -R $USR:$USR /home/$USR/.chrome
chmod -R 755 /home/$USR/.chrome

systemctl daemon-reload

systemctl start chrome-ramdisk-$USR.service && systemctl enable chrome-ramdisk-$USR.service

echo "Reboot system and use command - df -h ~/.chrome/ramdisk and mount | grep ram"
