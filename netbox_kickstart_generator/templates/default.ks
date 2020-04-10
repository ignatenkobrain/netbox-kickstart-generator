{% import "ifcfg.j2" as mod_ifcfg -%}
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
  {# TODO: Move this data to netbox -#}
  {% if data["type"] == "Bond" and "." not in interface -%}
    {% do data.update({"bonding_opts": "miimon=300 mode=802.3ad"}) -%}
  {% elif data["type"] == "Bridge" -%}
    {% do data.update({"stp": "no"}) -%}
  {% endif -%}
{% endfor -%}
{{ mod_ifcfg.write(ifcfg) -}}
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
