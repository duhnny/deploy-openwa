#!/bin/bash
set -e

# define macro to join a string
function join() {
  local -n outvar=$1
  shift 1;

  for arg in "$@"; do
      outvar="${outvar}${arg}";
  done;
}

# for loading environment variables
function load() {
    . ./utils/scripts/loadenv.sh < "$1"
}
function unload() {
    . ./utils/scripts/unloadenv.sh < "$1"
}

# load env variables from .env file
load .env

# check if docker stack name is setup correctly
if [[ -v DOCKER_STACK_NAME ]]; then
    if docker stack ls | grep -q "$DOCKER_STACK_NAME"; then
        echo stack with name "$DOCKER_STACK_NAME" already exists
        exit 1
    fi
else
    echo please set your stack name in the .env file
    exit 1
fi

# download necessary images
echo "-> donwloading images"

if docker image ls | grep -q "localhost/openwa"; then
    echo "-> openwa image exists"
else
    unload .env
    echo "ERROR: openwa image does not exist. Exiting."
    exit 1
fi

if [[ $(docker image ls | grep redis | grep "${REDIS_VERSION}") ]]; then
    echo "redis image already present"
else
    docker pull "redis:${REDIS_VERSION}-alpine" # &> /dev/null
    echo "downloaded redis image"
fi

# check necessary networks
if docker network ls | grep -q "${DB_NETWORK}"; then
    echo "-> db network exists"
else
    unload .env
    echo "ERROR: db network does not exist. Exiting."
    exit 1
fi

# create necessary networks
if docker network ls | grep -q "${WHATSAPP_NETWORK}"; then
    echo "-> whatsapp network already exists"
else
    docker network create \
        --attachable \
        --driver=overlay \
        "${WHATSAPP_NETWORK}"
    echo "-> created whatsapp network"
fi

# check necessary networks
if docker network ls | grep -q "${PUBLIC_NETWORK}"; then
    echo "-> public network exists"
else
    unload .env
    echo "ERROR: public network does not exist. Exiting."
    exit 1
fi

# do the cleanup
echo "-> cleaning up"

unload .env

echo "-> setup complete!"
exit
