assert = require "assert"
{describe} = require "amen"
{is_string, deep_equal} = require "fairmont"

describe "PBX", (context) ->

  context.test "Build", ->

    {Builder} = require "../src"
    builder = new Builder "test"

    builder.define "author",
      path: "/author"
      query:
        email: type: "string", required: true
    .get()
    .put()
    .delete()

    builder.define "blogs"
    .post as: "create", creates: "blog"

    builder.define "blog", template: "/blog/:key"
    .get()
    .put()
    .delete()
    .post creates: "post"

    builder.define "post", template: "/blog/:key/:index"
    .get()
    .put
      authorization: true
    .delete()

    # Test case for issue #15 -- this fails without the patch
    builder.define("test").post()

    builder.reflect()

    assert builder.api.resources.blogs?

    {classifier} = require "../src"
    classify = classifier builder.api

    context.test "Classify", (context) ->

      context.test "Simple GET request", ->
        request =
          url: "/blog/my-blog"
          method: "GET"
          headers:
            accept: "application/vnd.test.blog+json"

        match = classify request
        assert.equal match.resource.name, "blog"
        assert.equal match.path.key, "my-blog"
        assert.equal match.action.name, "get"

      context.test "With bad URL", ->
        try
          classify
            url: "/blurg"
            method: "GET"
            headers:
              accept: "application/vnd.test.author+json"
          assert false
        catch error
          assert error.status == "404"
          assert error.message == "Not Found"

      context.test "With bad accept header", ->
        try
          classify
            url: "/blog/my-blog"
            method: "GET"
            headers: {}
          assert false
        catch error
          assert error.status == "406"
          assert error.message == "Not Acceptable"

      context.test "With content-type header", ->
        match = classify
          url: "/blog/my-blog"
          method: "POST"
          headers:
            "content-type": "application/vnd.test.post+json"
        assert.equal match.resource.name, "blog"
        assert.equal match.path.key, "my-blog"
        assert.equal match.action.name, "post"

      context.test "With bad content-type header", ->
        try
          classify
            url: "/blog/my-blog"
            method: "POST"
            headers: {}
          assert false
        catch error
          assert error.status == "415"
          assert error.message == "Unsupported Media Type"

      context.test "With query parameters", ->

        match = classify
          url: "/author?email=danielyoder@gmail.com"
          method: "GET"
          headers:
            accept: "application/vnd.test.author+json"

        assert.equal match.resource.name, "author"
        assert.equal match.query.email, "danielyoder@gmail.com"
        assert.equal match.action.name, "get"

      context.test "With missing query parameter", ->
        try
          classify
            url: "/author"
            method: "GET"
            headers:
              accept: "application/vnd.test.author+json"
          assert false
        catch error
          assert error.status == "404"
          assert error.message == "Not Found"

      context.test "With authorization header", ->
        match = classify
          url: "/blog/my-blog/my-post"
          method: "PUT"
          headers:
            "content-type": "application/vnd.test.post+json"
            authorization: "token 12345"

        assert.equal match.resource.name, "post"
        assert.equal match.action.name, "put"

      context.test "With bad authorization header", ->
        try
          classify
            url: "/blog/my-blog/my-post"
            method: "PUT"
            headers:
              "content-type": "application/vnd.test.post+json"
          assert false
        catch error
          assert error.status == "401"
          assert error.message == "Unauthorized"

    context.test "Context", (context) ->
      Context = require "../src/context"

      cases =
        'string': "success"
        'object': { "foo": "bar" }
        'array': [1, 2, {"foo": "bar"}]

      for type, data of cases
        context.test "Context respond with #{type}", ->
          request =
            method: 'GET'
            url: '/users'
            headers: {}
            on: ->
          response =
            setHeader: ->
            write: (s) ->
              @content ?= ""
              @content += s
            end: ->

          ctx = Context.make {request, response, api: builder.api}
          ctx.respond 200, data
          # TODO: this test is not functional enough
          if is_string data
            assert data == response.content
          else
            assert deep_equal data, JSON.parse response.content

    context.test "Client", ->

      {describe} = (require "../src").client
      client = describe "http://localhost", builder.api

      assert.equal "curl -v -XGET http://localhost/blog/my-blog -H'accept: application/vnd.test.blog+json'",
        client
        .blog key: "my-blog"
        .get
        .curl()
