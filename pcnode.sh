#!/usr/bin/env bash

#set -exo pipefail

cd ./pcnode
sudo npm install
PORT=9002 node app.js