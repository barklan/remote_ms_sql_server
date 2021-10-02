#!/usr/bin/env bash

set -eo pipefail

DC="${DC:-exec}"

# If we're running in CI we need to disable TTY allocation for docker-compose
# commands that enable it by default, such as exec and run.
TTY=""
if [[ ! -t 1 ]]; then
    TTY="-T"
fi

# -----------------------------------------------------------------------------
# Helper functions start with _ and aren't listed in this script's help menu.
# -----------------------------------------------------------------------------

function _use_env {
    sort -u environment/.env | grep -v '^$\|^\s*\#' > './environment/.env.tempfile'
    export $(cat environment/.env.tempfile | xargs)
}

function _build_linter {
    docker inspect "linter" > /dev/null 2>&1 || docker build -t linter -f dockerfiles/linter.dockerfile .
}

# -----------------------------------------------------------------------------
# * Local functions.


function lint:sql:fix {
    _build_linter
    docker run --rm -it -v `pwd`:/workdir -w /workdir linter bash -c "
    sqlfluff fix $1 --force"
}

function lint:sql {
    _build_linter
    docker run --rm -it -v `pwd`:/workdir -w /workdir linter bash -c "
    sqlfluff fix $1 --force && sqlfluff lint --ignore parsing $1"
}

function ms:d {
    docker run --rm -e 'ACCEPT_EULA=Y' -p 1433:1433 -d \
    -v $(pwd)/sql:/userdir -w /userdir \
    --name 'msserver' 'mcr.microsoft.com/mssql/server:2019-latest'
}

function ms:shell {
    _use_env
    docker exec -it msserver /opt/mssql-tools/bin/sqlcmd \
    -S $MS_SQL_SERVER_HOST -U $MS_SQL_SERVER_USER -P $MS_SQL_SERVER_PASSWORD -d $MS_SQL_SERVER_DB
}

function ms:exec {
    _use_env
    docker exec -it msserver bash -c "cat $1 | /opt/mssql-tools/bin/sqlcmd \
    -S $MS_SQL_SERVER_HOST -U $MS_SQL_SERVER_USER -P $MS_SQL_SERVER_PASSWORD -d $MS_SQL_SERVER_DB \
    -i '/dev/stdin'" | tee sqlcmd.log
}

function clean:tempfiles {
    rm -f tempfile && find . -name "*.tempfile" -type f | xargs rm -f
}

# -----------------------------------------------------------------------------

function help {
    printf "%s <task> [args]\n\nTasks:\n" "${0}"

    compgen -A function | grep -v "^_" | cat -n
}

TIMEFORMAT=$'\nTask completed in %3lR'
time "${@:-help}"
