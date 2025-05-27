#!/bin/sh

PODMAN=podman-remote

$PODMAN ps

printf "12345" | $PODMAN secret create netbox-db-pass --replace -
printf "12345" | $PODMAN secret create redis-cache-pass --replace -
printf "12345" | $PODMAN secret create redis-pass --replace -
printf "12345" | $PODMAN secret create netbox-secret-key --replace -



$PODMAN pod create --replace \
    -p 80:8080 netbox

$PODMAN run -d \
    --name netbox-db \
    --pod netbox \
    --secret netbox-db-pass \
    -e POSTGRES_DB=netbox \
    -e POSTGRES_USER=netbox \
    -e POSTGRES_PASSWORD_FILE=/run/secrets/netbox-db-pass \
     -v netbox-db-data:/var/lib/postgresql/data \
    docker.io/postgres:17-alpine

$PODMAN run -d \
    --name redis \
    --pod netbox \
    --secret redis-pass \
    -v netbox-redis-data:/data \
    docker.io/valkey/valkey:8.1-alpine \
    valkey-server --appendonly yes --requirepass $(cat /run/secrets/redis-pass)

$PODMAN run -d \
    --name redis-cache \
    --pod netbox \
    --secret redis-cache-pass \
    -v netbox-redis-cache-data:/data \
    docker.io/valkey/valkey:8.1-alpine \
    valkey-server --requirepass $(cat /run/secrets/redis-cache-pass)

$PODMAN run -d \
    --name netbox \
    --pod netbox \
    --secret netbox-secret-key \
    --secret netbox-db-pass \
    --secret redis-cache-pass \
    --secret redis-pass \
    docker.io/netboxcommunity/netbox:latest

