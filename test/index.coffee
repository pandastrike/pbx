assert = require "assert"
{describe} = require "amen"
api = require "./api"

describe "PBX", (context) ->

  context.test "Build", ->

    Builder = require "../src/build"
    builder = new Builder "test"

    builder.define "blog"
    .get()

    builder.define "post", parent: "blog"
    .create()
    .get()
    .put()
    .delete()

    assert.deepEqual builder.api, api

    context.test "Classify", ->

      make_classifier = require "../src/classify"
      classify = make_classifier builder.api

      request =
        url: "/blog/my-blog"
        method: "GET"
        headers:
          accept: "application/vnd.test.blog+json"

      match = classify request
      assert.equal match.resource.name, "blog"
      assert.equal match.path.key, "my-blog"
      assert.equal match.action.name, "get"

    context.test "Client", ->

      {describe} = require "../src/client"
      client = describe "http://localhost", api

      assert.equal "curl -v -XGET http://localhost/blog/my-blog -H'accept: application/vnd.test.blog+json'",
        client
        .blog key: "my-blog"
        .get
        .curl()
