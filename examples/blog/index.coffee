processor = require "../../src/processor"
api = require "./api"

(require "http")
.createServer (processor api, {})
.listen 8080
