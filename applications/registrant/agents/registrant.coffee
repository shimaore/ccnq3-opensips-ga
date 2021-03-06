#!/usr/bin/env coffee

pico = require 'pico'
ccnq3 = require 'ccnq3'

# Agent main process
ccnq3.config (config) ->

  provisioning = pico config.provisioning.local_couchdb_uri

  handler = (p) ->

    if not p.registrant? then return

    base_path = "./opensips"
    model = 'registrant'

    params = require('./params') p

    # Build the configuration file.
    require("#{base_path}/compiler.coffee") params

  # At startup, use the current document.
  handler config

  # Then start monitoring forward.
  options =
    since_name: "registrant #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  provisioning.monitor options, handler
