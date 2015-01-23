{call} = require "when/generator"
{discover} = require "../../src/client"
amen = require "amen"
assert = require "assert"

cson = require "c50n"
{read} = require "fairmont"
{resolve} = require "path"

querystring = require "querystring"

call ->
  try
    aws = yield cson.parse (read(resolve("#{process.env.HOME}/.pandacluster.cson")))
  catch error
    assert.fail error, null, "Credential file ~/.pandacluster.cson missing"

amen.describe "Huxley API", (context) ->

  cluster_name = "peter-cli-test"
  email = aws.email

  context.test "Create a user", (context) ->

    api = yield discover "http://localhost:8080"

    {response: {headers: {secret_token}}} =
      (yield api.users.create data: aws)

    blog = (api.blog location)
    clusters = (api.clusters)

    context.test "Create a cluster", ->

      {response: {headers: {cluster_url}}} =
        (yield clusters.create
          cluster_name: cluster_name
          secret_token: secret_token
          email: email)

      cluster = (api.cluster cluster_url)

    context.test "Delete a cluster", ->

      {response: {headers: {cluster_url}}} =
        (yield clusters.delete
          secret_token: secret_token
          email: email)
