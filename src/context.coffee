{type, include} = require "fairmont"
{promise} = require "when"
{call} = require "when/generator"

# TODO: convert this to a real class definition
module.exports = class Context

  @make: (context) ->
    {request, response} = context
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
      "/" + components.join "/"

    context.respond = (status, content="", headers={}) ->
      response.statusCode = status
      headers["content-type"] =
        if context.match?.action?.response?.type? &&
        context.match.action.response.status == status
          context.match.action.response.type
        else
          "text/plain;charset=utf-8"
      # TODO: allow for other formatting conventions
      # besides JSON
      # TODO: allow for responding with a stream
      for key, value of headers
        response.setHeader key, value
      if type(content) == "object"
        response.write (JSON.stringify content)
      else
        response.write content
      response.end()

    context.error = ({status, message}) -> @respond status, message

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

    context
