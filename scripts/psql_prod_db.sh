#!/bin/bash

# First, run this command in your terminal
# fly proxy 15432:5432 -a ambiantcare-db

# Then, in another terminal window, run this
export $(cat .env) && psql $PROD_PROXIED_DATABASE_URL