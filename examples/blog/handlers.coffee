async = (require "when/generator").lift
{call} = require "when/generator"
{Memory} = require "pirate"
validate = require "../../src/filters/validate"

make_key = -> (require "key-forge").randomKey 16, "base64url"

adapter = Memory.Adapter.make()

module.exports = async ->

  blogs = yield adapter.collection "blogs"

  blogs:

    create: validate async ({respond, url, data}) ->
      key = make_key()
      yield blogs.put key, (yield data)
      respond 201, "", location: url "blog", {key}

  blog:

    # create post
    post: validate async ({respond, url, data,
    match: {path: {key}}}) ->
      blog = yield blogs.get key
      blog.posts ?= []
      index = blog.posts.length
      post = yield data
      post.index = index
      blog.posts.push post
      yield blogs.put key, blog
      respond 201, "",
        location: (url "post", {key, index})

    get: async ({respond, match: {path: {key}}}) ->
      blog = yield blogs.get key
      respond 200, blog

    put: validate async ({respond, data, match: {path: {key}}}) ->
      yield blogs.put key, (yield data)
      respond 200

    delete: async ({respond, match: {path: {key}}}) ->
      yield blogs.delete key
      respond 200

  post:

    get: async ({respond, match: {path: {key, index}}}) ->
      blog = yield blogs.get key
      post = blog.posts?[index]
      if post?
        context.respond 200, post
      else
        context.respond.not_found()

    put: validate async ({respond, data,
    match: {path: {key, index}}}) ->
      blog = yield blogs.get key
      post = blog.posts?[index]
      if post?
        blog.posts[index] = (yield data)
        respond 200
      else
        context.respond.not_found()

    delete: async ({respond, match: {path: {key, index}}}) ->
      blog = yield blogs.get key
      post = blog.posts?[index]
      if post?
        delete blog.posts[index]
        context.respond 200
      else
        context.respond.not_found()
