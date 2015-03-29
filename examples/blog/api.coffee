{Builder} = require "../../src"
builder = new Builder "blog-api"

builder.define "blogs",
  path: "/blogs"
.post
  as: "create"
  creates: "blog"

builder.define "blog",
  template: "/blogs/:name"
.get()
.put authorization: true
.delete  authorization: true
.post
  creates: "post"
  authorization: true
.schema
  required: ["name", "title"]
  properties:
    name: type: "string"
    title: type: "string"

builder.define "post",
  template: "/blog/:name/:key"
.get()
.put authorization: true
.delete authorization: true
.schema
  required: ["key", "title", "content"]
  properties:
    key: type: "string"
    title: type: "string"
    content: type: "string"

builder.reflect()

module.exports = builder.api
