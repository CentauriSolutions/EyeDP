# EYEdP

EYEdP is a federating identity provider. It is designed to be very self-contained and with minimal dependencies to run, so that it's very easy to setup. It exposes the configuration necessary to implement a SAML Identity Provider, as well as supporting an Nginx auth_request endpoint that will evaluate group based permissions.

## Usage

EYEdP is a fairly standard Rails application that expects a database connection.

## Development

To run EYEdP in development, it is recommended to use [Hivemind](https://github.com/DarthSim/hivemind) or [Overmind](https://github.com/DarthSim/overmind) like:

- `overmind s -f Procfile.dev`
- `hivemind Procfile.dev`

This will start up a development web server as well as watching for changes requiring updates. To handle initial setup, you should run `bin/setup` to ensure that the database is fully setup and ready to test!
