Context = require "./context"
classifier = require "./classifier"

module.exports = (api, handlers) ->
    # TODO: move classification into the context? con: outside of
    # url generation, the context class knows nothing of PBX
    classify = classifier api
    for resource, actions of handlers
      handlers[resource] = proxy actions

    (request, response) ->
      try
        match = classify request
        context = Context.make {request, response, api, match}
        {resource, action} = context.match
        action = handlers[resource.name]?[action.name]
        if action?
          try
            action context
          catch error
            context.error error
        else
          context.respond.not_implemented()
      catch error
        console.error error.stack
        response.statusCode = 500
        response.write "Server Error"
        response.end()
