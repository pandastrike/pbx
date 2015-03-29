{include, merge} = require "fairmont"

class Builder

  constructor: (@name, @api) ->
    @api ?=
      mappings: {}
      resources: {}
      schema:
        id: "urn:#{@name}"
        definitions:
          resource:
            id: "#resource"
            type: "object"
            properties:
              url:
                type: "string"
                format: "uri"
                readonly: true

  define: (name, {url, path, template, query}={}) ->
    if template?
      @map name, {template}
    else if url?
      @map name, {url: url}
    else
      path ?= "/#{name}"
      @map name, {path}
    if query?
      @map name, {query}
    @_schema(name)
    proxy =
      get: (options={}) => @get name, options; proxy
      put: (options={}) => @put name, options; proxy
      delete: (options={}) => @delete name, options; proxy
      post: (options={}) => @post name, options; proxy
      schema: (definition) =>
        include @api.schema.definitions[name], definition
        @

  map: (name, spec) ->
    include (@api.mappings[name] ?= resource: name), spec
    @

  _actions: (name) ->
    resource = @api.resources[name] ?= {}
    resource.actions ?= {}

  _schema: (name) ->
    @api.schema.definitions[name] ?=
      extends: {$ref: "urn:#{@name}#resource"}
      mediaType: (@media_type name)
      id: "##{name}"
      type: "object"

  media_type: (name) -> "application/vnd.#{@name}.#{name}+json"

  get: (name, {as, type, authorization, description}={}) ->
    as ?= "get"
    type ?= "application/vnd.#{@name}.#{name}+json"
    description ?= if @api.mappings[name].template?
      "Returns a #{name} resource with the given key"
    else
      "Returns the #{name} resource"

    @_actions(name)[as] =
      description: description
      method: "GET"
      request: {authorization}
      response:
        type: type
        status: 200
    @

  put: (name, {as, type, authorization, description}={}) ->
    as ?= "put"
    type ?= "application/vnd.#{@name}.#{name}+json"
    description ?= "Updates a #{name} resource with the given key"
    @_actions(name)[as] =
      description: description
      method: "PUT"
      request: {type, authorization}
      response: status: 200
    @

  delete: (name, {as, authorization, description}={}) ->
    as ?= "delete"
    description ?= "Deletes a #{name} resource with the given key"
    @_actions(name)[as] =
      description: description
      method: "DELETE"
      request: {authorization}
      response: status: 200
    @

  post: (name, {as, type, authorization, creates, description}={}) ->
    as ?= "post"
    if creates?
      type ?= "application/vnd.#{@name}.#{creates}+json"
      description ?=  "Creates a #{name} resource whose
        URL will be returned in the location header"
      @_actions(name)[as] =
        description: description
        method: "POST"
        request: {type, authorization}
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
          type: type.request, authorization
        response:
          type: type.response
          status: 200
      @

  reflect: ->
    @map "description", path: "/"
    @get "description",
      type: "application/json"
      description: "Returns a description of the API"

module.exports = Builder
