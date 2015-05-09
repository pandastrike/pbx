# API Reference

for `<%= @name %>`

## Resources

<% for rname, resource of @resources: %>

### <%= @title_case @plain_text rname %>

<%= resource.description %>

<% if (@mappings[rname].path)? :%>
`<%= @mappings[rname].path %>`
<% end %>

<% if (@mappings[rname].query)? :%>

##### Query Parameters

<% for key, value of @mappings[rname].query: %>
- `<%= key %>` <%= value.description %>
<% end %>

<% end %>

<% if (@mappings[rname].template)? :%>
`<%= @mappings[rname].template %>`
<% end %>

#### Actions

<% for aname, action of resource.actions: %>

* `<%= aname %>` <%= action.description %>

<% if action.request?.type? : %>
Request content-type(s): `<%= action.response.type %>`.
<% end %>

<% if action.response?.type? : %>
Response content-type(s): `<%= action.response.type %>`.
<% end %>

<% if action.response?.status? : %>
Returns a status code of `<%= action.response.status %>` on success.
<% end %>

<% end %>

<% if @schema.definitions[rname]? : %>
#### Schema

```json
<%- JSON.stringify @schema.definitions[rname], null, 2 %>
```

<% end %>

<% end %>
