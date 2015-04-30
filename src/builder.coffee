mime = require "mime-db"
{properties, include, merge, is_array, cat} = require "fairmont"

class Builder

  constructor: (@name, @api) ->
    @api ?=
      name: @name
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

  define: (name, {url, path, template, query, description}={}) ->
    @api.resources[name] = {name, description}
    if template?
      @map name, {template}
    else if url?
      @map name, {url: url}
    else
      path ?= "/#{name}"
      @map name, {path}
    if query?
      @map name, {query}
    proxy =
      get: (options={}) => @get name, options; proxy
      put: (options={}) => @put name, options; proxy
      delete: (options={}) => @delete name, options; proxy
      post: (options={}) => @post name, options; proxy
      schema: (args...) =>
        if args.length == 1
          [definition] = args
          _name = name
        else
          [_name, definition] = args
        include @_schema(_name), definition
        proxy

  map: (name, spec) ->
    include (@api.mappings[name] ?= resource: name), spec
    @

  _actions: (name) ->
    resource = @api.resources[name] ?= {}
    resource.actions ?= {}

  _schema: (name, version="1.0") ->
    @api.schema.definitions[name] ?=
      extends: {$ref: "urn:#{@name}#resource"}
      mediaType:
        "application/vnd.#{@name}.#{name}+json;
        version=#{version};
        charset=UTF-8"
      id: "##{name}"
      type: "object"

  media_type: (name, version) ->
    if is_array name
      names = name
      (@media_type name, version) for name in names
    else if !version? && mime[name]?
      name
    else
      @_schema(name, version).mediaType

  get: (name, {as, type, authorization, description}={}) ->
    as ?= "get"
    type ?= name
    description ?= if @api.mappings[name].template?
      "Returns a #{name} resource with the given key"
    else
      "Returns the #{name} resource"

    action = @_actions(name)[as] =
      description: description
      method: "GET"
      request: {authorization}
      response: status: 200, type: @media_type(type)
    @

  put: (name, {as, type, authorization, description}={}) ->
    as ?= "put"
    type ?= name
    description ?= "Updates a #{name} resource with the given key"
    action = @_actions(name)[as] =
      description: description
      method: "PUT"
      request: {authorization, type: @media_type(type)}
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
      type ?= creates
      description ?=  "Creates a #{name} resource whose
        URL will be returned in the location header"
      action = @_actions(name)[as] =
        description: description
        method: "POST"
        request: {authorization, type: @media_type(type)}
        response: status: 201
    else
      description ?= "" # maybe issue a warning here? throw?
      type ?=
        request: name
        response: name
      action = @_actions(name)[as] =
        description: description
        method: "POST"
        request: {authorization}
        response: status: 200
      if type.request?
        action.request.type = @media_type(type.request)
      if type.response?
        action.response.type = @media_type(type.response)
      @

  reflect: ->
    @define "description",
      description: "A description of the API"
      path: "/"
    .get
      description: "Returns a description of the API"
      type: [
          "application/json"
          "text/html"
          "text/plain"
        ]

module.exports = Builder
