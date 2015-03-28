assert = require "assert"
{describe} = require "amen"

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
    .put()
    .delete()

    builder.reflect()

    assert builder.api.resources.blogs?

    {classifier} = require "../src"
    classify = classifier builder.api

    context.test "Classify", ->

      request =
        url: "/blog/my-blog"
        method: "GET"
        headers:
          accept: "application/vnd.test.blog+json"

      match = classify request
      assert.equal match.resource.name, "blog"
      assert.equal match.path.key, "my-blog"
      assert.equal match.action.name, "get"

    context.test "Classify with query parameters", ->

      match = classify
        url: "/author?email=danielyoder@gmail.com"
        method: "GET"
        headers:
          accept: "application/vnd.test.author+json"

      assert.equal match.resource.name, "author"
      assert.equal match.query.email, "danielyoder@gmail.com"
      assert.equal match.action.name, "get"

    context.test "Classify with missing query parameter", ->
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

    context.test "Client", ->

      {describe} = (require "../src").client
      client = describe "http://localhost", builder.api

      assert.equal "curl -v -XGET http://localhost/blog/my-blog -H'accept: application/vnd.test.blog+json'",
        client
        .blog key: "my-blog"
        .get
        .curl()
