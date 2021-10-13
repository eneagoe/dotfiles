#!/usr/bin/env bash

# source https://gist.github.com/nabucosound/8181671
set -e

sourceApp="$1"
targetApp="$2"

while read key value; do
  key=${key%%:}
  echo "Setting $key=$value"
  heroku config:set "$key=$value" --app "$targetApp"
done  < <(heroku config --app "$sourceApp" | sed -e '1d')
