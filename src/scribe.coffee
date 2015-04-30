{resolve} = require "path"
eco = require "eco"
{async, read, compose, merge, plain_text, title_case} = require "fairmont"
{lift} = require "when/node"
marked = require "marked"

plain_text = (string) ->
    string
      .replace( /^[A-Z]/g, (c) -> c.toLowerCase() )
      .replace( /[A-Z]/g, (c) -> " #{c.toLowerCase()}" )
      .replace( /\W+/g, " " )
      .replace( /_/g, " ")

module.exports = create: ->

  to_markdown = async (api) ->
    helpers = {title_case, plain_text}
    template = yield read resolve __dirname, "..", "src", "scribe.md"
    (eco.render template, merge helpers, api)
    .replace /([ \t]*\n){3,}/gm, "\n\n"

  to_html = async (api) ->
    styles = yield read resolve __dirname, "..", "src", "scribe.css"
    marked ((yield to_markdown api) + "<style>#{styles}</style>")

  {to_html, to_markdown}
