{resolve} = require "when"
async = (require "when/generator").lift
JSCK = require("jsck").draft4
Context = require "./context"
classifier = require "./classifier"
scribe = require "./scribe"

module.exports = async (api, initialize) ->

    # TODO: move classification into the context? con: outside of
    # url generation, the context class knows nothing of PBX
    classify = classifier api

    handlers = (yield (resolve initialize(api)))

    if api.resources.description?
      {to_html, to_markdown} = yield scribe.create()
      handlers.description ?=
        get: async ({request, respond}) ->
          {accept} = request.headers
          accept ?= "text/plain"
          if accept.match /json/
            respond 200, api,
              "content-type": "application/json"
          else if accept.match /html/
            respond 200, (yield to_html api),
              "content-type": "text/html"
          else
            respond 200, (yield to_markdown api),
              "content-type": "text/plain"

    api.schema.validate = do ->
      jsck = (new JSCK api.schema )
      (type, object) ->
        jsck.validator(mediaType: type).validate(object)

    async (request, response) ->
      try
        context = Context.make {request, response, api}
        try
          context.match = classify request
          {resource, action} = context.match
          action = handlers[resource.name]?[action.name]
          if action?
            try
              yield action context
            catch error
              context.error error
          else
            context.respond.not_implemented()
        catch error
          context.error error
      catch error
        console.error error.stack
        response.statusCode = 500
        response.write "Server Error"
        response.end()
