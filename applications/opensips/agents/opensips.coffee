#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

fs = require 'fs'
dgram = require 'dgram'

opensips_command = (port,command) ->
  # Connect to the MI datagram port
  # Send command
  message = new Buffer(command)
  client = dgram.createSocket "udp4"
  client.on 'error', (e) ->
    console.error "Socket failed"
  client.send message, 0, message.length, port, "127.0.0.1", (err, bytes) ->
    # FIXME we might receive data (and might want to report it)
    # FIXME the proper way to do so is to collect it then implement a timeout (say 1s)
    #       to declare the UDP session over with.
    client.close()

#  Quoting from the documentation for OpenSIPS' mi_datagram module:
#  The external commands issued via DATAGRAM interface must follow
#  the following syntax:
#    * request = first_line (argument '\n')*
#    * first_line = ':'command_name':''\n'
#    * argument = (arg_name '::' (arg_value)? ) | (arg_value)
#    * arg_name = not-quoted_string
#    * arg_value = not-quoted_string | '"' string '"'
#    * not-quoted_string = string - {',",\n,\r}

process_changes = (port,command) ->
  switch command
    when 'reload routes'
      opensips_command port, ":dr_reload:\n"

# Main

util = require 'util'
pico = require 'pico'

require('ccnq3').config (config) ->

  # Aggregate back towards the main database if requested.
  require('./aggregate') config

  handler = (p) ->

    # If the host does not support OpenSIPS then skip this update.
    return unless p.opensips?.model?

    # 1. Generate new configuration files
    base_path = "./opensips"

    params = {}
    for _ in ['default.json',"#{p.opensips.model}.json"]
      do (_) ->
        data = JSON.parse fs.readFileSync "#{base_path}/#{_}"
        params[k] = data[k] for own k of data

    params[k] = p.opensips[k] for own k of p.opensips

    params.opensips_base_lib = base_path
    params.sip_domain_name = config.sip_domain_name

    require("#{base_path}/compiler.coffee") params

    # 2. Process any MI commands
    if p.sip_commands?.opensips?
      process_changes params.mi_port, p.sip_commands.opensips

  # First start with the current configuration.
  handler config

  # Monitor for changes and commands.
  src = pico config.provisioning.local_couchdb_uri

  options =
    since_name: "opensips #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  src.monitor options, handler
