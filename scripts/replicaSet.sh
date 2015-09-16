#!/bin/bash
############# Setting up Replication set in mongoDB Notes #############
#
# How to execute this script
# run the following command in terminal prompt:
# ./replicaSet.sh {env}
	# where {env} can be:   local | production
# Configuration for Production environment has not been set, as it may vary a lot according to nº hosts, etc.

############# End Pre-script Notes #############

# Loading sys.argv variables to figure out environment

if [[ $1 == "local"]]; then
  CONFIG_DIR=""
  SECRETS_DIR=""
elif [[ $1 == "production"]]; then
  #CHANGE THE NEXT TO ADJUST TO LOCAL DIR STRUCTURE
  CONFIG_DIR="/INSERT_DIRECTORY"
	SECRETS_DIR="/INSERT_DIRECTORY"
else
  #For safety reasons, if no option is added, then do not execute the script
  echo "Please add one the following options to the script:"
  echo "Option A:"
  echo "./replicaSet.sh local"
  echo ".. if script should be run on local pc environment for test purposes"
  echo "Option B:"
  echo "./replicaSet.sh production""
  echo ".. if script should be run on production environment"
  exit 0
fi

### Load environment variables
if [ -f "$CONFIG_DIR/$1_global_env_vars.cfg" ]; then
	source $CONFIG_DIR/$1_global_env_vars.cfg
fi

### Action begins here:
NOW=$(date +"%d-%m-%Y-%H-%M")
# Redirect output to a logfile
exec 1>> $CONFIG_DIR/replSet_$NOW.txt 2>&1


if [[ $1 == "local"]]; then
  echo "Creating data folders.."
  mkdir -p $MONGO_DIR/data/rs1 $MONGO_DIR/data/rs2 $MONGO_DIR/data/rs3

  echo "Starting mongod Services adjacent to port: $PORT.."
  mongod --replSet $REPLICASET_NAME --logpath "1.log" --dbpath $MONGO_DIR/data/rs1 --port $PORT --oplogSize 64 --smallfiles --fork
  mongod --replSet $REPLICASET_NAME --logpath "2.log" --dbpath $MONGO_DIR/data/rs2 --port $($PORT +1) --oplogSize 64 --smallfiles --fork
  mongod --replSet $REPLICASET_NAME --logpath "3.log" --dbpath $MONGO_DIR/data/rs3 --port $($PORT +2) --oplogSize 64 --smallfiles --fork

  echo "initiating replicaset now.."
  mongo <<EOF
    config = { _id: "$REPLICASET_NAME", members:[
              { _id : 0, host : "$HOSTNAME:$PORT"},
              { _id : 1, host : "$HOSTNAME:$($PORT +1)"},
              { _id : 2, host : "$HOSTNAME:$($PORT +2)"} ]
    };

    rs.initiate(config);
    rs.status();
  EOF
  echo "Finished job. Exiting now.."

elif [[ $1 == "production"]]; then
  echo "please adjust this script to your production env, according to nº hosts, etc. you need.."
  #Do NOT copy from above, as it is set to smallfiles and oplogSize small. Example:
  #mongod --replSet $REPLICASET_NAME --logpath "1.log" --dbpath $MONGO_DIR/data/rs1 --port $PORT --fork
  echo "exiting now.."
fi
