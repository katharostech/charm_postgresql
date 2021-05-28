#!/bin/bash
set -e

# Source the helper functions
. functions.sh

# Set status to maintenance
lucky set-status -n config-status maintenance \
  "Updating PostgreSQL configuration"

# Load bash variables with configuration settings
pgtag=$(lucky get-config POSTGRES_DOCKER_TAG)
if [ -z $pgtag ]; then lucky set-status -n config-status blocked \
  "Config required: 'POSTGRES_DOCKER_TAG'"; exit 0; 
fi
pgpass=$(lucky get-config POSTGRES_PASSWORD)
if [ -z $pgpass ]; then lucky set-status -n config-status blocked \
  "Config required: 'POSTGRES_PASSWORD'"; exit 0; 
fi
pguser=$(lucky get-config POSTGRES_USER)
pgdb=$(lucky get-config POSTGRES_DB)

# Set the container image
lucky container image set "postgres:${pgtag}"

# Specify a named data volume that will be used for DB data
lucky container volume add pgdata /var/lib/postgresql/data

# Load container env vars with config settings
lucky container env set \
  "POSTGRES_PASSWORD=${pgpass}"
if [ -n $pguser ]; then
  lucky container env set \
    "POSTGRES_USER=${pguser}"
else
  lucky container env set \
    "POSTGRES_USER=postgres"
fi
if [ -n $pgdb ]; then
  lucky container env set \
    "POSTGRES_DB=${pgdb}"
else
  lucky container env set \
    "POSTGRES_DB=postgres"
fi

# Set up the ports
set_container_port
bind_port=$(lucky kv get bind_port)

# Remove previously opened ports
lucky port close --all
lucky container port remove --all

# Bind the app port
lucky container port add "${bind_port}:5432"

lucky set-status -n config-status active
