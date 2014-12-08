# TODO: It probably makes sense to move this into a utility class:

make_error = (status, message) ->
  ->
    error = new Error message
    error.status = status
    error

errors =
  not_found: make_error 404, "Not Found"
  method_not_allowed: make_error 405, "Method Not Allowed"
  not_acceptable: make_error 406, "Not Acceptable"
  unsupported_media_type: make_error 415, "Unsupported Media Type"
  # internal_server_error: make_error 500, "Internal Server Error"
  # not_implemented: make_error 501, "Not Implemented"


module.exports = (api) ->

  router = do (require "routington")

  for rname, resource of api.resources
    {path, template} = api.mappings[rname]
    path ?= template
    [node] = router.define path
    node.resource = name: rname, actions: {}

    for aname, action of resource.actions
      node.resource.actions[action.method.toUpperCase()] = action
      action.name = aname

  url = require "url"

  (request) ->

    path = (url.parse request.url).pathname
    if (route = router.match path)?
      {node: {resource}, param} = route
      # TODO: check query parameters
      match = { resource, path: param, query: {} }
      if (match.action = resource?.actions?[request.method])?
        if request.headers.accept == match.action.response?.type
          if request.headers["content-type"] == match.action.request?.type
            match
          else
            throw errors.unsupported_media_type()
        else
          throw errors.not_acceptable()
      else
        throw errors.method_not_allowed()
    else
      throw errors.not_found()
