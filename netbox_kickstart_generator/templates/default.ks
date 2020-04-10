lang en_US
keyboard us
timezone Europe/Prague --isUtc
rootpw $1$V0IQdLpc$SW/rAxJktPvvYfAkOSBlI1 --iscrypted
#platform x86, AMD64, or Intel EM64T
text
network --hostname={{ device.name }}
#cdrom
bootloader --location=mbr --append="mitigations=off"
zerombr
clearpart --all --initlabel
autopart
auth --passalgo=sha512 --useshadow
selinux --permissive
firewall --disabled
skipx
firstboot --disable

%pre
rpm -qa
%end

%post
# Configure networking
{% for interface, data in ifcfg.items() -%}
  cat > /etc/sysconfig/network-scripts/ifcfg-{{ interface }} << EOF
{% for k, v in data.items() -%}
  {{ k | upper }}={{ v }}
{% endfor -%}
{# TODO: Move this data to netbox -#}
{% if data["type"] == "Bond" and "." not in interface -%}
  BONDING_OPTS="miimon=300 mode=802.3ad"
{% elif data["type"] == "Bridge" -%}
  STP=no
{% endif -%}
  EOF
{% endfor -%}
%end

%packages
@standard
nfs-utils
nvmetcli
-dnf-plugin-spacewalk
-fprintd-pam
-plymouth
-rhn-client-tools
-rhn-setup
-rhnlib
-cockpit
-nano
-subscription-manager-cockpit
-subscription-manager-plugin-container
-insights-client
-rhnsd
%end
