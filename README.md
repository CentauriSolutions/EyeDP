# EYEdP

EYEdP is a federating identity provider. It is designed to be very self-contained and with minimal dependencies to run, so that it's very easy to setup. It exposes the configuration necessary to implement a SAML Identity Provider, as well as supporting an Nginx auth_request endpoint that will evaluate group based permissions.

## Contents

- [Overview](#overview)
- [Usage](#usage)
- [Deployment](#deployment)
  + [heroku](#heroku)
  + [docker](#docker)
- [Identity Provider](#identity-provider)
  + [OpenID Connect](#openid-connect)
  + [SAML](#saml)
  + [Nginx Auth Request](#nginx-auth-request)
- [Development](#development)

## Overview

### Users and Groups

The basic model for users and groups in EYEdP is similar to the model of LDAP, where users can be members of many groups, and a group can be nested. In addition, there is the concept of permissions which are inherited by a user from their groups.

#### Users

A User is an entity that can sign into the identity provider. They have an email, two factor authentication keys, etc. Through their membership in various groups, they can have many permissions associated.

#### Groups

A Group is a named collection of Groups and Permissions.

#### Permissions

A Permission is the name given to a capability for a group.

## Usage

EYEdP is a fairly standard Rails application that expects a database connection. The easiest way to setup an instance of EYEdP is to use the pre-built Docker container and attach it to a postgres container. An example topology can be seen in the [docker-compose.yml](./docker-compose.yml) in the main repository.

Alternately, a normal Ruby on Rails environment can be used to setup EYEdP, such as Heroku, a normal virtual machine, or a dedicated machine. The only required setup to get the application running it to configure the database.yml with the necessary options to configure the PostgreSQL database. The easiest way to configure the database is to export a `DATABASE_URL` environment veriable to the Rails process. Before starting EYEdP for the first time, the administrator should ensure that they run `bin/setup` to ensure that the database is ready for use.

## Deployment

### Heroku

#### One-Click Heroku Deployment

The easiest way to start using EyeDP is by deploying it to
[Heroku](https://www.heroku.com/).

If you are reading this document in a browser all you need to do is click the
button bellow and fill in the environment variables for your seed user (admin):
`SEED_USERNAME`, `SEED_PASSWORD` and `SEED_EMAIL`. Please note that `SEED_PASSWORD` must be at least 8 characters long. 

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/centaurisolutions/eyedp)

A free Heroku plan could be used to run EyeDP at a small scale, but it is worth
using hobby or larger for any kind of production deployment.

### Docker

The easiest way to get started hosting EyeDP on your own infrastructure
is to use Docker Compose. The following can be customized to your needs and
should be places behind a load-balancer, such as Traefik or Nginx.

```yaml
version: '3'
services:
 db:
  image: postgres
  volumes:
    - 'postgres:/var/lib/postgresql/data'
  environment:
    - POSTGRES_USER=postgres
    - POSTGRES_PASSWORD=super-secure-password
 web:
  image: eyedp-now
  volumes:
    - ./log:/eyedp/log
  ports:
    - "3000:3000"
  depends_on:
    - db
  links:
    - db
  environment:
    - RAILS_ENV=production
    - DATABASE_URL=postgres://postgres:super-secure-password@db:5432/eyedp
    - SECRET_KEY_BASE=o8w64gurfvwtiu64wlyregfvcw74iu6eryfV
    - DISABLE_SSL=true
    - RAILS_SERVE_STATIC_FILES=true
volumes:
  postgres:
```

After configuring this how you want it, you can initialize the database and
first admin user with `docker-compose run web bin/setup` and then you can start
the application with `docker-compose up -d`.

When you're ready to put a load balancer in front of EyeDP, it is recommended
to configure it to  aggressively cache resources that come from the `/assets`
path, as these include hashes to ensure that they are highly cachable as well
as updatable by the application. An example configuration for Nginx follows:

```
proxy_cache_path /var/cache/nginx/eyedp levels=1:2
                   keys_zone=eyedp:10m max_size=1g inactive=60m;

upstream app {
    server localhost:3000 fail_timeout=0;
}

server {
    listen 80;
    server_name localhost;

    proxy_cache_key $scheme$request_method$host$request_uri;
    
    location /assets/ {
        proxy_redirect off;
        proxy_pass_header Cookie;
        proxy_ignore_headers Set-Cookie;
        proxy_hide_header Set-Cookie;

        proxy_cache eyedp;
        proxy_cache_valid 200 302  120m;
        proxy_cache_valid 404      1m;

        proxy_pass http://app;
    }


    location / {
        proxy_pass http://app;
        # This assumes that you actually are using https
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
    }

    error_page 500 502 503 504 /500.html;
    client_max_body_size 4G;
    keepalive_timeout 10;
}
```

## Identity Provider

EYEdP supports many different authentication frameworks, allowing it to be integrated with many different service providers.

To start setting up Identity Providers, the admin should configure the `idp_base` setting to be the fully qualified domain name (FQDN) of the authentication server.

### OpenID Connect

OpenID Connect requires setting up the  `signing_key`. The signing key can be generated via a command like `openssl genpkey -algorithm RSA -out key.pem -pkeyopt rsa_keygen_bits:2048`. 

### SAML

Saml requires a few pieces of configuration, `certificate` and `key`. Generating SAML's key and certificate should look like: `openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout myKey.key -out myCert.crt`. This will generate a key and certificate with an expiration of ten years. It is entirely possible to change this expiration time as well. 

### Nginx Auth Request

The Nginx Auth Request backend is a fairly basic, group membership based permission check that allows implementing access restriction to applications that may not have their own acess controls at the Nginx layer. To learn more about how to use it, an admin should peruse the [groups](#groups) section of the documentetion.


## Development

To setup your development environment, ensure that you have a postgres
user setup that can create the database (either your current user, or setup the
environment variables in .env correctly) and run
`bundle exec rails db:create db:migrate db:seed`. After the database has been
initialized, you can run the development server with
`bundle exec rails server`.
