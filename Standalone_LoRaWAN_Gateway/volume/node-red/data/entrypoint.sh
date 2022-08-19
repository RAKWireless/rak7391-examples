#!/bin/sh

DIR=`pwd`

cd /data
npm install

cd "$DIR"
npm start -- --userDir /data
