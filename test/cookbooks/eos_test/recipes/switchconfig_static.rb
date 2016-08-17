#
# Cookbook Name:: eos_test
# Recipe:: switchconfig_static
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

# rubocop:disable LineLength
config = '
event-handler dhclient
   trigger on-boot
   action bash sudo /mnt/flash/initialize_ma1.sh
!
transceiver qsfp default-mode 4x10G
!
ip name-server vrf default 8.8.8.8
!
spanning-tree mode mstp
!
aaa authorization exec default local
!
aaa root secret 5 $1$kJoSHuJm$TFgwpIkLdAgGm/Ve4MaDu.
!
username admin privilege 15 role network-admin secret 5 $1$zadebI3e$j.TmSB.xnIblL3ekQG8vJ/
username vagrant privilege 15 role network-admin secret 5 $1$x7IKkFIE$GI5r4DQcD1yEkAMiSfLi80
!
interface Ethernet1
!
interface Ethernet2
!
interface Management1
   ip address 10.0.2.15/24
!
ip route 0.0.0.0/0 10.0.2.2
!
no ip routing
!
management api http-commands
   protocol unix-socket
   no shutdown
!
!
end'
# rubocop:enable LineLength

eos_switchconfig 'running-config' do
  content config
  action :create
end
