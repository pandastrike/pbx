async = (require "when/generator").lift
{call} = require "when/generator"
{Memory} = require "pirate"

pandacluster = require "../../../src/pandacluster"

make_key = -> (require "key-forge").randomKey 16, "base64url"

adapter = Memory.Adapter.make()


module.exports = async ->

  clusters = yield adapter.collection "clusters"

  users = yield adapter.collection "users"

  clusters:

    ###
    cluster: cluster_url
      email: String
      url: String
      name: String
    ###
    create: async ({respond, url, data}) ->
      cluster_url = make_key()
      user = yield users.get data.email
      if user && data.secret_token == user.secret_token
        cluster_entry =
          email: data.email
          url: cluster_url
          name: data.cluster_name
        yield clusters.put cluster_url, (yield data)
        res = yield pandacluster.create user
        respond 201, "", location: url "blog", {key}
      respond 401, "invalid email or token"

  cluster:

    # FIXME: need data (cluster_url) in signature argument
    delete: async ({respond, match: {path: {cluster_url}}, data}) ->
      user = yield users.get data.email
      if user && data.secret_token == user.secret_token
        cluster = yield clusters.get cluster_url
        request_data =
          aws: user.aws
          stack_name: cluster.name
        yield clusters.delete cluster_url
        pandacluster.delete request_data
        respond 200
      respond 401, "invalid email or token"

  users:

    # FIXME: testing purposes only, delete after
    get: async ({respond, match: {path: {key}}}) ->
      blog = yield users.get key
      respond 200, blog

    ###
    user: email
      public_keys: Array[String]
      key_pair: String
      aws: Object
      email: String
    ###
    create: async ({respond, url, data}) ->
      key = make_key()
      data.secret_token = key
      yield users.put data.email, (yield data)
      respond 201, "", secret_token: key
      #respond 201, "", location: url "blog", {key}




  blogs = yield adapter.collection "blogs"

  blogs:

    create: async ({respond, url, data}) ->
      key = make_key()
      yield blogs.put key, (yield data)
      respond 201, "", location: url "blog", {key}

  blog:

    # create post
    create: async ({respond, url, data,
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

    put: async ({respond, data, match: {path: {key}}}) ->
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

    put: async ({respond, data,
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
