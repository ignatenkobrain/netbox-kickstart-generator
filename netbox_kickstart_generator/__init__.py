from flask import Flask, abort, request, render_template
import pynetbox

def create_app():
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object("netbox_kickstart_generator.default_settings")
    app.config.from_pyfile("config.py", silent=True)

    @app.route("/kickstart")
    def kickstart():
        if "X-System-Serial-Number" not in request.headers:
            abort(400, "No Serial Number")
        nb = pynetbox.api(app.config["NETBOX_URL"], token=app.config["NETBOX_TOKEN"])
        try:
            device = nb.dcim.devices.get(serial=request.headers["X-System-Serial-Number"])
        except ValueError:
            abort(409, "Multiple entries with same serial number found")
        interfaces = nb.dcim.interfaces.filter(device_id=device.id)
        ips = nb.ipam.ip_addresses.filter(device_id=device.id)
        prefixes = {}
        for ip in ips:
            prefix = [p for p in nb.ipam.prefixes.filter(site_id=device.site.id, contains=ip.address)
                      if p.vlan is not None]
            if len(prefix) != 1:
                raise AssertionError(f"None or multiple prefixes found for: {ip.address}")
            prefixes[ip.address] = prefix[0]
        return render_template("test.ks",
                               device=device,
                               interfaces={i.id: i for i in interfaces
                                           if i.lag is not None
                                           or i.type.value == "lag"},
                               ips=ips,
                               prefixes=prefixes)

    return app
