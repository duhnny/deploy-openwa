set -e

# load .env file
. ./utils/scripts/loadenv.sh < .env

# load env variables in the service folders
while read -r env_file; do
    if [[ $env_file =~ services/([^/]+)/\.env ]]; then
        . ./utils/scripts/loadenv.sh --uri --prefix=$(echo ${BASH_REMATCH[1]} | sed s/-//g) < $env_file
    fi
done < <(ls services/*/.env) # here we do process substitution to avoid subshells

# run stack
docker stack up \
    --compose-file=$DOCKER_COMPOSE_FILE \
    --detach=true \
    $DOCKER_STACK_NAME
