Builder = require "../../src/build"
builder = new Builder "test"

builder.define "blog"
.create parent: "blogs"
.get()
.put()
.delete()

builder.define "post", template: "/blog/:blog/:post"
.create parent: "blog"
.get()
.put()
.delete()

builder.reflect()

module.exports = builder.api
