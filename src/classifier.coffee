{w, first, isArray, isString} = require "fairmont"
errors = require "./errors"
JSCK = require("jsck").draft3

# TODO: make this more sophisticated
# Negotiator takes a stab at all the parsing, but you have to use
# it on the request. We should perhaps do that for dealing with
# charsets, encodings, ...
acceptable = (header, definition) ->
  header == definition ||
    ((isString header) && (header.indexOf "*/*") != -1) ||
    ((isArray definition) && (header in definition))

supported = (header, definition) ->
  (header == definition) ||
    (isArray definition && header in definition)

validator = (schema) ->
  if schema?
    _validator = (new JSCK {properties: schema})
    (object) ->
      {valid} = _validator.validate object
      valid
  else
    (object) ->
      # handle null, undefined, or {}
      # to mean 'empty query string'
      unless object?
        true
      else
        Object.keys(object).length == 0

module.exports = (api) ->

  router = do (require "routington")

  for rname, resource of api.resources
    {path, template, query} = api.mappings[rname]
    path ?= if template? then template else url
    [node] = router.define path
    node.resource =
      name: rname
      actions: {}
      query: {validate: (validator query)}
    for aname, action of resource.actions
      node.resource.actions[action.method.toUpperCase()] = action
      action.name = aname

  url = require "url"

  {not_found, method_not_allowed, not_acceptable,
    unsupported_media_type, unauthorized} = errors

  throws = (f, g) ->
    (args...) -> if  (r = g args...)? then r else throw f()

  matchURL = throws errors.not_found, (request) ->
    {pathname, query} = (url.parse request.url, true)
    path = pathname
    if (route = router.match path)?
      {node: {resource}, param} = route
      if (resource.query.validate query)
        match = { resource, path: param, query }
        {resource, path: param, query}

  matchAction = throws method_not_allowed, (request, match) ->
    match if (match.action = match.resource?.actions?[request.method])?

  matchAccept = throws not_acceptable, (request, match) ->
    match if (acceptable request.headers.accept, match.action.response?.type)

  matchContent = throws unsupported_media_type, (request, match) ->
    match if (supported request.headers["content-type"],
                match.action.request?.type)

  matchAuthorization = throws unauthorized, (request, match) ->
    if (authorization = match.action.request?.authorization)?
      if (header = request.headers["authorization"])?
        # TODO Add auth scheme to match
        match if (authorization == true) || ((first w header) == authorization)
    else
      match

  (request) ->
    matchAuthorization request,
      matchContent request,
        matchAccept request,
          matchAction request,
            matchURL request
