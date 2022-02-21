#!/usr/bin/env bash
set -ueo pipefail

ISO=/kvm/iso/Rocky-8.5-x86_64-minimal.iso

GetVars() {
  read -p "VM Name: " NAME
  read -p "VCPU(s): " VCPU
  read -p "Memory(MiB): " MEM
  read -p "Disk(GiB): " SIZE
  read -p "Bridge: " BRIDGE
  read -p "IP Address: " IP
  read -p "Netmask: " NM
  read -p "Gateway: " GW
  read -p "DNS Server: " DNS
}

GenKickstart() {
cat << EOF > kickstart.cfg
lang en_US
keyboard us
timezone America/New_York
# changeme
rootpw \$6\$tYcP0XfjkKS9fxuY\$Zs8PAGSSKUzTwZwtbN8dqaXRplCtvcW6p/7CFXGRBLVv7rDSVVpkgUNuvQUybdQ11ZnUitpnYvzEsFOAeI5Pr/ --iscrypted
#platform x86_64
reboot
text
cdrom
bootloader --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart --noswap --nohome --fstype=ext4
network --device=ens2 --bootproto=static --ip=$IP --netmask=$NM --gateway=$GW --nameserver=$DNS
repo --name=BaseOS --baseurl=https://download.rockylinux.org/pub/rocky/8/BaseOS/x86_64/os/
repo --name=AppStream --baseurl=https://download.rockylinux.org/pub/rocky/8/AppStream/x86_64/os/
auth --passalgo=sha512 --useshadow
selinux --disabled
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
%end
EOF
}

Provision() {
  virt-install \
    --name $NAME \
    --memory $MEM \
    --vcpus $VCPU \
    --os-type linux \
    --os-variant generic \
    --disk size=$SIZE \
    --network network=$BRIDGE \
    --location $ISO \
    --graphics none \
    --initrd-inject ./kickstart.cfg \
    --console pty,target_type=serial \
    --extra-args "inst.ks=file:kickstart.cfg console=tty0 console=ttyS0,115200n8"
}

GetVars
read -n1 -p "Continue [yn]? " yn; echo
[ "${yn,,}" != y ] && { echo bye.; exit 0; }
GenKickstart
Provision
