{merge} = require "fairmont"

blank =
  mappings: {}
  resources: {}
  schema: { definitions: {}}

collection = (name) ->
  "#{name}_collection"

class Builder

  constructor: (@name, @api = blank) ->

  define: (name, {parent}={}) ->
    parent ?= collection name
    @map name, template: "/#{name}/:key"
    @_schema(name).mediaType = "application/vnd.#{@name}.#{name}+json"
    proxy =
      get: => @.get name; proxy
      put: => @.put name; proxy
      delete: => @.delete name; proxy
      create: =>
        @map parent, path: "/#{parent}"
        @.create name, parent
        proxy

  map: (name, spec) ->

    @api.mappings[name] ?= merge spec,
      resource: name
    @

  _actions: (name) ->
    resource = @api.resources[name] ?= {}
    resource.actions ?= {}

  _schema: (name) ->
    schema = @api.schema.definitions[name] ?= {}

  get: (name) ->
    @_actions(name).get =
      description: "Returns a #{name} resource with the given key"
      method: "GET"
      response:
        type: "application/vnd.#{@name}.#{name}+json"
        status: 200
    @

  put: (name) ->
    @_actions(name).put =
      description: "Updates a #{name} resource with the given key"
      method: "PUT"
      request: type: "application/vnd.#{@name}.#{name}+json"
      response: status: 200
    @

  delete: (name) ->
    @_actions(name).delete =
      description: "Deletes a #{name} resource with the given key"
      method: "DELETE"
      response: status: 200
    @

  create: (name, parent) ->
    @_actions(parent).create =
      description: "Creates a #{name} resource whose
        URL will be returned in the location header"
      method: "POST"
      request: type: "application/vnd.#{@name}.#{name}+json"
      response: status: 201
    @

module.exports = Builder
