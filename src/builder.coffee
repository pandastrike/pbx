{merge} = require "fairmont"

blank =
  mappings: {}
  resources: {}
  schema: { definitions: {}}

collection = (name) ->
  "#{name}_collection"

class Builder

  constructor: (@name, @api = blank) ->

  define: (name, {path, template}={}) ->
    if template?
      @map name, {template}
    else
      path ?= "/#{name}"
      @map name, {path}
    @_schema(name).mediaType = "application/vnd.#{@name}.#{name}+json"
    proxy =
      get: (options={}) => @get name, options; proxy
      put: (options={}) => @put name, options; proxy
      delete: (options={}) => @delete name, options; proxy
      post: (options={}) => @post name, options; proxy

  map: (name, spec) ->
    @api.mappings[name] ?= merge spec,
      resource: name
    @

  _actions: (name) ->
    resource = @api.resources[name] ?= {}
    resource.actions ?= {}

  _schema: (name) ->
    schema = @api.schema.definitions[name] ?= {}

  get: (name, {as, type, description}={}) ->
    as ?= "get"
    type ?= "application/vnd.#{@name}.#{name}+json"
    description ?= if @api.mappings[name].template?
      "Returns a #{name} resource with the given key"
    else
      "Returns the #{name} resource"

    @_actions(name)[as] =
      description: description
      method: "GET"
      response:
        type: type
        status: 200
    @

  put: (name, {as, type, description}={}) ->
    as ?= "put"
    type ?= "application/vnd.#{@name}.#{name}+json"
    description ?= "Updates a #{name} resource with the given key"
    @_actions(name)[as] =
      description: description
      method: "PUT"
      request: type: type
      response: status: 200
    @

  delete: (name, {as, description}={}) ->
    as ?= "delete"
    description ?= "Deletes a #{name} resource with the given key"
    @_actions(name)[as] =
      description: description
      method: "DELETE"
      response: status: 200
    @

  post: (name, {as, type, creates, description}={}) ->
    as ?= "post"
    if creates?
      type ?= "application/vnd.#{@name}.#{creates}+json"
      description ?=  "Creates a #{name} resource whose
        URL will be returned in the location header"
      @_actions(name)[as] =
        description: description
        method: "POST"
        request: {type}
        response: status: 201
    else
      description ?= "" # maybe issue a warning here? throw?
      type ?=
        request: "application/vnd.#{@name}.#{name}+json"
        response: "application/vnd.#{@name}.#{name}+json"
      @_actions(name)[as] =
        description: description
        method: "POST"
        request:
          type: request.type
        response:
          type: response.type
          status: 200
      @

  reflect: ->
    @map "description", path: "/"
    @get "description",
      type: "application/json"
      description: "Returns a description of the API"

module.exports = Builder
