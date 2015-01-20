# PBX

> **Warning** This is an experimental project.

PBX is a reimagining of [Patchboard][1] with the following design goals:

* Support for the Patchboard API description schema

* Modularization of the architecture

* Simplification of request classification

* Support for ES6 (mostly via generator/promise-based interfaces)

* Optimizations for common development scenarios

Although PBX is currently a single library, the idea is to package and release it as several standalone libraries that can interoperate. We want to empower developers to pick and choose the tools they want to use and to ultimately be able to create their our Patchboard-based solutions.

These components include:

* A validator that uses [JSCK][2] for JSON schema validation. Validators are used to validate API definitions, query parameters, and request and response bodies.

* A client that uses [Shred][3] to generate HTTP API clients based on the API definition.

* A builder for creating API definitions quickly, much like you can do with frameworks like [Restify][4] and [Express][5] (except the definitions are valid Patchboard API definitions and can be discovered/reflected upon).

* A classifier for determining the `(resource, action)` pair associated with a given request.

* A context object that provides a series of helper methods for dealing with requests and responses, leveraging the API definition to do so.

* A processor that provides a standard request handler for use with the [Node HTTP API][6].

* A collection of behaviors encapsulating common API scenarios, such as providing an HTTP interface to a storage backend.

[1]:https://github.com/patchboard
[2]:https://github.com/pandastrike/jsck
[3]:https://github.com/pandastrike/shred
[4]:http://mcavage.me/node-restify/
[5]:http://expressjs.com/
[6]:http://nodejs.org/docs/v0.11.13/api/http.html#http_http_createserver_requestlistener

## Example: A Simple Blog Engine

First, let's define our API:

```coffee
Builder = require "pbx/builder"
builder = new Builder "blogly"

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
```

This API allows to create blogs, view and update them, and delete them. We can also do the same for posts within a blog. We also added reflection to our API, which means the Patchboard API definition is available via a `GET` request to `/`.

For example, if we have a blog named `my-blog` and a post named `pbx-example`, the API above would allow us to read that post with the following `curl` command:

```
$ curl 'http://acmeblogging.com/blog/my-blog/pbx-example'
    -H'accept:application.vnd.post+json;version=1.0
```

Let's serve up the API using the Node HTTP `createServer` method:

```coffee
processor = require "pbx/processor"

(require "http")
.createServer (processor builder.api, {})
.listen 8080
```

If we run this, we'll have an HTTP server for our API running on port `8080` on `localhost`.

Wait, though…this API doesn't actually _do_ anything. We haven't created any behaviors to bind it to. That's why the handlers object passed into the processor above is empty: `{}`.
