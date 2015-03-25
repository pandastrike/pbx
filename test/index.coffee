assert = require "assert"
{describe} = require "amen"
{liftAll} = require "when/node"
{readFile} = (liftAll (require "fs"))
{resolve, join} = require "path"
httpMocks = require "node-mocks-http"
YAML = require "js-yaml"

describe "PBX", (context) ->

  context.test "Build", ->

    {Builder} = require "../src"
    builder = new Builder "test"

    builder.define "blogs"
    .post as: "create", creates: "blog"

    builder.define "blog", template: "/blog/:key"
    .get()
    .put()
    .delete()
    .post creates: "post"

    builder.define "post", template: "/blog/:key/:index"
    .get()
    .put()
    .delete()

    builder.reflect()

    assert builder.api.resources.blogs?

    context.test "Classify", ->

      {classifier} = require "../src"
      classify = classifier builder.api

      request =
        url: "/blog/my-blog"
        method: "GET"
        headers:
          accept: "application/vnd.test.blog+json"

      match = classify request
      assert.equal match.resource.name, "blog"
      assert.equal match.path.key, "my-blog"
      assert.equal match.action.name, "get"

    # fold this into the example API
    context.test "Classify with query parameters", ->
      {classifier} = require "../src"
      classify = classifier
        mappings:
          user:
            resource: "user"
            path: "/users"
            query:
              login:
                required: true
                type: "string"
        resources:
          user:
            actions:
              get:
                method: "GET"
                response:
                  type: "application/json"
                  status: 200
        schema:
          definitions:
            user:
              mediaType: "application/json"

      match = classify
        url: "/users?login=dyoder"
        method: "GET"
        headers:
          accept: "application/json"

      assert.equal match.resource.name, "user"
      assert.equal match.query.login, "dyoder"
      assert.equal match.action.name, "get"

    context.test "Context", (context) ->
      Context = require "../src/context"

      TestData =
        'string': "success"
        'object': { "foo": "bar" }
        'array': [1, 2, {"foo": "bar"}]
        'buffer': new Buffer "success"

      for type, data of TestData
        context.test "Respond with #{type}", ->
          # we need to mock a request and response to use the context
          request = httpMocks.createRequest 
            method: 'GET'
            url: '/users'

          # the mock request does not include `on`, but the context expects it
          request.on ?= ->

          response = httpMocks.createResponse()

          ctx = Context.make {request, response, api: builder.api}
          ctx.respond 200, data

          assert.equal 200, response._getStatusCode()
          if type == 'string' or type == 'buffer'
            assert.equal data.toString(), response._getData()
          else
            assert.deepEqual data, JSON.parse response._getData()

    context.test "Client", ->

      {describe} = (require "../src").client
      client = describe "http://localhost", builder.api

      assert.equal "curl -v -XGET http://localhost/blog/my-blog -H'accept: application/vnd.test.blog+json'",
        client
        .blog key: "my-blog"
        .get
        .curl()
