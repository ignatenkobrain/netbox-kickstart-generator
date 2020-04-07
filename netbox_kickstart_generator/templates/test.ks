#jinja2: lstrip_blocks: True
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
{% for interface in interfaces.values() %}
  {% if interface.lag is none %}
    cat > ifcfg-{{ interface.name }} << EOF
TYPE=Bond
BONDING_MASTER=yes
DEVICE={{ interface.name }}
BRIDGE=br_{{ interface.untagged_vlan.name }}
MTU={{ interface.mtu }}
EOF
    {% for vlan in interface.tagged_vlans %}
      cat > ifcfg-{{ interface.name }}.{{ vlan.vid }} << EOF
VLAN=yes
DEVICE={{ interface.name }}.{{ vlan.vid }}
BRIDGE=br_{{ vlan.name }}
EOF
    {% endfor %}
    {% for ip in ips %}
      {% set prefix = prefixes[ip.address] %}
      cat > ifcfg-br_{{ prefix.vlan.name }} << EOF
DEVICE=br_{{ prefix.vlan.name }}
IPADDR={{ ip.address.split('/')[0] }}
NETMASK={{ ip.address.split('/')[-1] }}
EOF
    {% endfor %}
  {% else %}
    cat > ifcfg-{{ interface.name }} << EOF
DEVICE={{ interface.name }}
MASTER={{ interfaces[interface.lag.id].name }}
EOF
  {% endif %}
{% endfor %}
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
