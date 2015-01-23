{call} = require "when/generator"
processor = require "../../src/processor"
initialize = require "./handlers"
api = require "./api"
api.base_url = "http://localhost:8080"

call ->
  (require "http")
  .createServer yield (processor api, initialize)
  .listen 8080, ->
    console.log "pbx listening to #{api.base_url}"
