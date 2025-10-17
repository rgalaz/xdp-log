#!/usr/bin/env bash

### Build ubuntu vm

NAME="bpf-testing-wg"

if [ ! -f noble-server-cloudimg-amd64.img ]; then
  curl https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img --output ./noble-server-cloudimg-amd64.img
fi

echo "instance-id: $NAME" >meta-data
echo "local-hostname: $NAME" >>meta-data

cp user-data.yaml user-data # must be named user-data

qemu-img create -b noble-server-cloudimg-amd64.img -f qcow2 -F qcow2 "$NAME.img" 30G
genisoimage -output "cidata-$NAME.iso" -V cidata -r -J user-data meta-data
virt-install --connect qemu:///system \
  --name="$NAME" \
  --ram=4096 --vcpus=4 \
  --import --disk path="$NAME.img",format=qcow2 --disk path="cidata-$NAME.iso",device=cdrom \
  --os-variant=ubuntu24.04 \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole

virsh -c qemu:///system console $NAME

#
IP=$(virsh -c qemu:///system qemu-agent-command "$NAME" --cmd '{"execute":"guest-network-get-interfaces"}' | jq '.return[1]."ip-addresses"[0]."ip-address"' -r)

ssh cloud@$IP
