# netbox-kickstart-generator

Generate [kickstart](https://pykickstart.readthedocs.io) files
based on the data in [netbox](https://netbox.readthedocs.io).

## Configuration

Create `config.py` in the `instance` folder that contains:

* `NETBOX_URL`
* `NETBOX_TOKEN`

## Running and Testing

```sh
poetry run env FLASK_APP=netbox_kickstart_generator flask run
```

If you wish to run in development mode, set `FLASK_ENV` to `development`:

```sh
export FLASK_ENV=development
```

To see the kickstart which would be generated for specific SN, run:

```sh
curl http://127.0.0.1:5000/kickstart -H "X-System-Serial-Number: MXQ7140CHN"
```

## Contributing

Make sure to run `black` before each commit to ensure code style.
