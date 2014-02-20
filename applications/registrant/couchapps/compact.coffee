#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config)->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.compact_design 'registrant', pico.log
