Builder = require "../../src/builder"
builder = new Builder "test"

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

builder.define "post",
  template: "/blog/:key/:index"
.get()
.put()
.delete()

builder.reflect()

module.exports = builder.api
