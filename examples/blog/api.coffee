Builder = require "../../src/builder"
builder = new Builder "blog-api"

builder.define "blogs",
  path: "/blogs"
.post
  as: "create"
  creates: "blog"

builder.define "blog",
  template: "/blogs/:key"
.get()
.put()
.delete()
.post
  creates: "post"
.schema
  required: ["title"]
  properties:
    key: type: "string"
    title: type: "string"

builder.define "post",
  template: "/blog/:key/:index"
.get()
.put()
.delete()
.schema
  required: ["title", "content"]
  properties:
    key: type: "string"
    title: type: "string"
    index: type: "string"

builder.reflect()

module.exports = builder.api
