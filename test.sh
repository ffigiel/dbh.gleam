#!/usr/bin/env bash

set -e
docker-compose exec -u postgres postgres psql -c 'drop database if exists test'
docker-compose exec -u postgres postgres psql -c 'create database test'
gleam test
