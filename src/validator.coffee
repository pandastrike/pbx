JSCK = require("jsck").draft3

module.exports = (schema) ->
  if schema?
    validator = (new JSCK {properties: schema})
    (object) ->
      {valid} = validator.validate object
      valid
  else
    (object) ->
      # handle null, undefined, or {}
      # to mean 'empty query string'
      unless object?
        true
      else
        Object.keys(object).length == 0
