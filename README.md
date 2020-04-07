# netbox-kickstart-generator

Generate [kickstart](https://pykickstart.readthedocs.io) files
based on the data in [netbox](https://netbox.readthedocs.io).

## Configuration

Create `config.py` in the `instance` folder that contains:

* `NETBOX_URL`
* `NETBOX_TOKEN`

## Running

```sh
env FLASK_APP=netbox_kickstart_generator flask run
```

If you wish to run in development mode, set `FLASK_ENV` to `development`:

```sh
export FLASK_ENV=development
```

## Testing

```sh
curl http://127.0.0.1:5000/kickstart -H "X-System-Serial-Number: MXQ7140CHN"
```
