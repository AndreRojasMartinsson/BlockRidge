#!/bin/bash
ARG=$1

set_env() {
  if [ ! -f .env ]; then
    echo "Fatal: .env file not found"
    exit 1
  fi

}

do_sync() {
  set_env

  if [[ $ARG = 'github' ]]; then
    echo "Pulling from remote for environment $CMD"

    git fetch origin
    git pull main
  fi

  echo "Syncing to $CMD environment"

  export $(cat .env | xargs) && lune run "import-$CMD"
  scripts/sync-assets.sh
  rojo build -o game.rbxl

  echo "Synced to environment"
}

do_sync

