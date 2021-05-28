# function to send log messages to a file
log_this () {

  # create the logfile if needed
  if [ !${logfile_created} ]; then
    # gather some data
    now=$(date "+%Y%m%d-%H%M%S")
    logdir=/var/log/lucky
    script="${0}"
    scriptbase=$(basename -s ".sh" "${script}")
    logname="postgresql-${scriptbase}"
    logfile="${logdir}/${logname}-${now}.log"

    # create the dir if it doesn't exist
    mkdir -p ${logdir}
    touch ${logfile}
    # say we created it
    logfile_created=true
  fi

  # write message to log
  echo "${LUCKY_HOOK}::${1}" >> ${logfile}

  # clean up files older than 10 minutes
  find ${logdir} -name "${logname}-*" -mmin +10 -print | xargs rm -f
}

# Function to set the http interface relation
# Convention found here: https://discourse.jujucharms.com/t/interface-http/2392
set_db_relation () {
  # Get the port from the KV store
  app_port=$(lucky kv get bind_port)

  # Log it
  log_this "hostname: $(lucky private-address)"
  log_this "port: ${app_port}"

  # Publish host and port
  lucky relation set "hostname=$(lucky private-address)"
  lucky relation set "port=${app_port}"

  # Publish required fields
  lucky relation set "docker_tag=$(lucky get-config POSTGRES_DOCKER_TAG)"
  lucky relation set "POSTGRES_PASSWORD=$(lucky get-config POSTGRES_PASSWORD)"
  
  # Publish optional fields if provided, otherwise publish defaults
  pguser=$(lucky get-config POSTGRES_USER)
  pgdb=$(lucky get-config POSTGRES_DB)
  if [ -n $pguser ]; then
    lucky relation set "POSTGRES_USER=$pguser"
  else
    lucky relation set "POSTGRES_USER=postgres"
  fi
  if [ -n $pgdb ]; then
    lucky relation set "POSTGRES_DB=$pgdb"
  else
    lucky relation set "POSTGRES_DB=postgres"
  fi
}

# function to remove the listen_address
remove_db_relation () {
  lucky relation set hostname=""
  lucky relation set port=""
  lucky relation set docker_tag=""
  lucky relation set POSTGRES_PASSWORD=""
  lucky relation set POSTGRES_USER=""
  lucky relation set POSTGRES_DB=""
}

# Get random port if not set
set_container_port () {
  if [ -z "$(lucky kv get bind_port)" ]; then
    # Use random function of Lucky
    rand_port=$(lucky random --available-port)
    lucky kv set bind_port="$rand_port"
  fi
}
