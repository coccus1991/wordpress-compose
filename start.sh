#!/bin/sh
sudo -E docker-compose down
sudo -E docker-compose rm
sudo -E docker-compose up -d
