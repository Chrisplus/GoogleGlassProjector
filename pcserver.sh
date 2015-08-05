#!/usr/bin/env bash
#set -exo pipefail

cd ./pcnode
npm install
PORT=9002 node app.js