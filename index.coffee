{EventEmitter} = require 'events'
debug          = require('debug')('meshblu-config-restart')
XXHash         = require 'xxhash'
{spawn}        = require 'child_process'

class Plugin extends EventEmitter
  constructor: ->
    @options = {}
    @key = process.env.CONFIG_RESTART_KEY

  restart: =>
    @process?.kill 'SIGKILL'
    @process = spawn 'node', ['command.js'], stdio: 'inherit'
    @process.on 'exit', (code, signal) =>
      console.log 'process exited', code, signal
      process.exit code unless signal == 'SIGKILL'

  onMessage: =>
    debug 'onMessage'

  onConfig: (device) =>
    debug 'onConfig'

    @restart() unless @lastHash == @generateHash device[@key]
    @setOptions device

  setOptions: (options={}) =>
    debug 'setOptions'
    @options = options

    @lastHash = @generateHash options[@key]

  generateHash: (value=null) =>
    buffer = new Buffer JSON.stringify value
    XXHash.hash buffer, 0

module.exports =
  Plugin: Plugin
