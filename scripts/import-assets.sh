#!/bin/bash

CMD=$1

echo "Importing from place"
export $(cat .env | xargs) && lune run import-place 
