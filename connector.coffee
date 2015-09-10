MeshbluWebsocket  = require 'meshblu-websocket'
{EventEmitter} = require 'events'
{Plugin} = require './index'
debug          = require('debug')('meshblu-config-restart')
Backoff = require 'backo'

class Connector extends EventEmitter
  constructor: (@config={}) ->
    process.on 'uncaughtException', @emitError
    @backoff = new Backoff min: 1000, max: 60 * 60 * 1000

  createConnection: =>
    @config.protocol ?= 'http' unless @config.port == 443
    @config.pingTimeout = 30000
    @meshblu = new MeshbluWebsocket @config
    @meshblu.connect()

    @meshblu.on 'notReady', @emitError
    @meshblu.on 'error', @onError

    @meshblu.on 'ready', @onReady
    @meshblu.on 'message', @onMessage
    @meshblu.on 'config', @onConfig
    @meshblu.on 'close', @reconnectWithBackoff

  onConfig: (device) =>
    @emit 'config', device
    try
      @plugin.onConfig arguments...
    catch error
      @emitError error

  onError: (error) =>
    console.error error.message
    @reconnectWithBackoff()

  onMessage: (message) =>
    @emit 'message.recieve', message
    try
      @plugin.onMessage arguments...
    catch error
      @emitError error

  onReady: =>
    @meshblu.whoami uuid: @config.uuid
    @meshblu.on 'whoami', (device) =>
      @plugin.setOptions device

  reconnectWithBackoff: =>
    randomNumber = Math.random() * 5
    reconnectTimeout = @backoff.duration() * randomNumber
    debug "reconnecting in #{reconnectTimeout}ms"
    setTimeout @reconnect, reconnectTimeout

  reconnect: =>
    debug 'reconnect'
    @meshblu.reconnect()

  run: =>
    @plugin = new Plugin();
    @createConnection()
    @plugin.on 'data', (data) =>
      @emit 'data.send', data
      @meshblu.data data

    @plugin.on 'error', @emitError

    @plugin.on 'message', (message) =>
      @emit 'message.send', message
      @meshblu.message message

    @plugin.restart()

  emitError: (error) =>
    @emit 'error', error

module.exports = Connector;
