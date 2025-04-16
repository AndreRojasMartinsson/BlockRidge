#!/bin/bash

scripts/sync-assets.sh
rojo build -o place.rbxl

mantle deploy --environment production

