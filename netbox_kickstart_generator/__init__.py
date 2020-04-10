from collections import defaultdict
import netaddr
from flask import Flask, abort, request, render_template
from flask.templating import TemplateNotFound
import pynetbox


def create_app():
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object("netbox_kickstart_generator.default_settings")
    app.config.from_pyfile("config.py", silent=True)
    app.jinja_options["extensions"].append("jinja2.ext.do")

    @app.route("/kickstart")
    @app.route("/kickstart/<kickstart>")
    def kickstart(kickstart="default"):
        if "X-System-Serial-Number" not in request.headers:
            abort(400, "No Serial Number")
        nb = pynetbox.api(app.config["NETBOX_URL"], token=app.config["NETBOX_TOKEN"])
        try:
            device = nb.dcim.devices.get(
                serial=request.headers["X-System-Serial-Number"]
            )
        except ValueError:
            abort(409, "Multiple entries with same serial number found")
        interfaces = {i.id: i for i in nb.dcim.interfaces.filter(device_id=device.id)}
        ips = nb.ipam.ip_addresses.filter(device_id=device.id)
        ifcfg = {}
        for interface in interfaces.values():
            if interface.mgmt_only:
                continue
            if interface.type.value == "lag":
                if interface.mode.value != "tagged":
                    raise NotImplementedError("Only tagged LAGs are supported")
                ifcfg[interface.name] = {
                    "type": "Bond",
                    "mtu": interface.mtu,
                    "bonding_master": "yes",
                }
                if interface.untagged_vlan:
                    bridge = f"br_{interface.untagged_vlan.name}"
                    ifcfg[interface.name]["bridge"] = bridge
                    ifcfg[bridge] = {"type": "Bridge"}
                for vlan in interface.tagged_vlans:
                    bridge = f"br_{vlan.name}"
                    ifcfg[f"{interface.name}.{vlan.vid}"] = {
                        "type": "Vlan",
                        "physdev": interface.name,
                        "vlan_id": vlan.vid,
                        "bridge": bridge,
                        "vlan": "yes",
                    }
                    ifcfg[bridge] = {"type": "Bridge"}
                # TODO: Add support for multiple IPs on one interface
                for ip in ips:
                    if interfaces[ip.interface.id].id != interface.id:
                        continue
                    prefixes = [
                        p
                        for p in nb.ipam.prefixes.filter(
                            site_id=device.site.id, contains=ip.address
                        )
                        if p.vlan is not None
                    ]
                    if len(prefixes) != 1:
                        raise AssertionError(
                            f"None or multiple prefixes found for: {ip.address}"
                        )
                    prefix = prefixes[0]
                    ipaddr = netaddr.IPNetwork(ip.address)
                    bridge = f"br_{prefix.vlan.name}"
                    ifcfg[bridge].update(
                        {"ipaddr": ipaddr.ip, "prefix": ipaddr.prefixlen}
                    )
                    # FIXME: Probably store this info in netbox?
                    if prefix.vlan.name == "public":
                        ifcfg[bridge]["gateway"] = ipaddr[1]
            else:
                ifcfg[interface.name] = {
                    "type": "Ethernet",
                    "master": interfaces[interface.lag.id].name,
                    "slave": "yes",
                }
        for i, data in ifcfg.items():
            ifcfg[i].update({"device": i, "name": i, "onboot": "yes"})

        try:
            return render_template(f"{kickstart}.ks", device=device, ifcfg=ifcfg)
        except TemplateNotFound:
            abort(404, "Template not found")

    return app
