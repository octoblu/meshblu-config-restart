MeshbluConfig = require 'meshblu-config'
Connector = require './connector'

config = new MeshbluConfig
connector = new Connector config.toJSON()

connector.on 'error', (error) ->
  console.error error

connector.run()
