Builder = require "../../src/builder"
builder = new Builder "test"

builder.define "blog"
.create parent: "blogs"
.get()
.put()
.delete()

builder.define "post", template: "/blog/:key/:index"
.create parent: "blog"
.get()
.put()
.delete()

builder.reflect()

module.exports = builder.api
