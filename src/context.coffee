{include, isString} = require "fairmont"
{promise} = require "when"
{call, lift} = require "when/generator"
async = lift
{resolve} = require "url"
toJSON = (x) -> JSON.stringify x, null, 2


# TODO: convert this to a real class definition
module.exports = class Context

  @make: (context) ->
    {request, response} = context
    {validate} = context.api.schema
    context.url = (name, object) ->
      # TODO: this is the only place where we need to reference
      # the API; otherwise, this could be completely PBX neutral
      template = context.api.mappings[name]?.template
      throw "No URL mapping for #{name}" unless template?
      components = for component in (template.split "/")[1..]
        if component[0] == ":"
          key = component[1..]
          throw "URL mapping for #{name}
            requires #{key}" unless object[key]?
          object[key]
        else
          component

      resolve context.api.baseURL, (components.join "/")

    context.respond = (status, content="", headers={}) ->
      response.statusCode = status
      content ?= "" # turn explicit null into ""

      # TODO: Rethink the logic here a bit. In particular,
      # how to determine the expected response type when there
      # are multiple supported formats.
      if context.match?.action?.response?
        expected = context.match.action.response
        # attempt to set the content-type based on the API definition
        # presuming we're dealing with the expected response
        if status == expected.status && expected.type?
          headers["content-type"] ?= expected.type

        # otherwise, don't set the content-type unless it's something
        # besides an empty string and it isn't already set...
        unless content == ""
          headers["content-type"] ?= "text/plain;charset=utf-8"

      for key, value of headers
        response.setHeader key, value

      # TODO: allow for responding with a stream
      # TODO: allow for other formatting conventions besides JSON
      response.write (if isString content then content else toJSON content)
      response.end()

    context.error = (error) ->
      if error.status?
        {status, message} = error
        @respond status, message
      else
        throw error

    # context.respond.not_implemented, and so on
    for error, fn of (require "./errors")
      do (error, fn) ->
        context.respond[error] = -> context.error fn()

    context.body = promise (resolve, reject) ->
      do (body = "") ->
        request.on "data", (data) -> body += data
        request.on "end", ->  resolve body
        request.on "error", -> reject error

    context.data = call ->
      if request.headers["content-type"]?.match(/json/)
        JSON.parse yield context.body

    context.validate = async =>
      if context.match.action.request.type?
        {valid, errors} =
          validate context.match.action.request.type, (yield context.data)
        if !valid
          # TODO: add errors to message
          # JSON.stringify(errors, null, 2)
          context.respond.bad_request()
        valid
      else
        true

    context
