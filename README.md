JaSerializer
============

[![Build Status](https://travis-ci.org/AgilionApps/ja_serializer.svg?branch=master)](https://travis-ci.org/AgilionApps/ja_serializer)
[![Hex Version](https://img.shields.io/hexpm/v/ja_serializer.svg)](https://hex.pm/packages/ja_serializer)
[![Inline docs](http://inch-ci.org/github/AgilionApps/ja_serializer.svg)](http://inch-ci.org/github/AgilionApps/ja_serializer)

jsonapi.org formatting of Elixir data structures suitable for serialization by
libraries such as Poison.

Warning: This is Alpha software and subject to breaking changes.

## Usage

See [documentation](http://hexdocs.pm/ja_serializer/) on hexdoc for full
serialization and usage details.

### Serializer Behaviour and DSL:

```elixir
defmodule MyApp.ArticleSerializer do
  use JaSerializer

  location "/articles/:id"
  attributes [:title, :tags, :body, :excerpt]

  has_one :author,
    serializer: PersonSerializer,
    include: true,
    field: :authored_by

  has_many :comments,
    link: "/articles/:id/comments",

  def comments(model, _conn) do
    Comment.for_article(model)
  end

  def excerpt(article, _conn) do
    [first | _ ] = String.split(article.body, ".")
    first
  end
end
```

#### Attributes

Attributes are defined as a list in the serializer module.
The serializer will use the given atom as the key by default.
You can also specify a custom method of attribute retrieval by defining a
<attribute_name>/2 method. The method will be passed the model
and the connection.

#### Relationships

Valid relationships are: `has_one`, `has_many`.
For each relationship, you can define the name and a variety of options.
Just like attributes, the serializer will use the given atom
to look up the relationship, unless you specify a custom retrieval method
OR provide a `field` option

##### Relationship options

* serializer - The serializer to use when serializing this resource
* include - boolean - true to always side-load this relationship
* field - custom field to use for relationship retrieval
* link - custom link to use in the `relationships` hash

### Direct Usage

```elixir
model
|> MyApp.ArticleSerializer.format(conn)
|> Poison.encode!
```

### Formatting options

The `format/3` method is able to take in options that can customize the
serialized payload.

#### include

By specifying the `include` option, the serializer will only side-load
the relationships specified. This option should be a comma separated
list of relationships. Each relationship should be a dot separated path.

Example: `include: "author,comments.author"`

The format of this string should exacly match the one specified by the
[JSON-API spec](http://jsonapi.org/format/#fetching-includes)

Note: If specifying the `include` option, all "default" includes will
be ignored, and only the specified relationships included, per spec.

#### fields

The `fields` option satisfies the [sparse fieldset](http://jsonapi.org/format/#fetching-sparse-fieldsets) portion of the spec. This options should
be a map of resource types whose value is a comma separated list of fields
to include.

Example: `fields: %{"articles" => "title,body", "comments" => "body"}`

If you're using Plug, you should be able to call `fetch_query_params(conn)`
and pass the result of `conn.query_params["fields"]` as this option.

### Relax Usage

See [Relax](https://github.com/AgilionApps/relax) documentation for building
fully compatible jsonapi.org APIs with Plug.

### Phoenix Usage

Simply `use JaSerializer.PhoenixView` in your view (or in the Web module) and
define your serializer as above.

The `render("index.json", data)` and `render("show.json", data)` are defined
for you. You can just call render as normal from your controller.

```elixir
defmodule PhoenixExample.ArticlesController do
  use PhoenixExample.Web, :controller

  def index(conn, _params) do
    render conn, model: PhoenixExample.Repo.all(PhoenixExample.Article)
  end

  def show(conn, params) do
    render conn, model: PhoenixExample.Repo.get(PhoenixExample.Article, params[:id])
  end

  def create(conn, params) do
    changeset = PhoenixExample.Article.changeset(%PhoenixExample.Article{}, create_params(params))
    if changeset.valid? do
      conn
      |> put_status(201)
      |> render(:show, data: changeset.model)
    else
      conn
      |> put_status(422)
      |> render(:errors, data: changeset)
    end
  end

  defp create_params(params) do
    # extract relevant attributes and relationships here.
  end
end

defmodule PhoenixExample.ArticlesView do
  use PhoenixExample.Web, :view
  use JaSerializer.PhoenixView # Or use in web/web.ex

  attributes [:title]
  #has_many, etc.
end
```


To use the Phoenix `accepts` plug you must configure Plug to handle the
"application/vnd.api+json" mime type.

Add the following to `config.exs`:

```elixir
config :plug, :mimes, %{
  "application/vnd.api+json" => ["json-api"]
}
```

And then re-compile plug: (per: http://hexdocs.pm/plug/Plug.MIME.html)

```shell
touch deps/plug/mix.exs
mix deps.compile plug

# For tesing
MIX_ENV=test mix deps.compile plug
```

And then add json api to your plug pipeline.

```elixir
pipeline :api do
  plug :accepts, ["json-api"]
end
```

For strict content-type/accept enforcement and to auto add the proper
content-type to responses add the JaSerializer.ContentTypeNegotiation plug.

To normalize attributes to underscores include the JaSerializer.Deserializer
plug.

```elixir
pipeline :api do
  plug :accepts, ["json-api"]
  plug JaSerializer.ContentTypeNegotiation
  plug JaSerializer.Deserializer
end
```

### Testing controllers

Set right headers in setup and when passing parameters to put, post requests
you should pass them as a binary. That is because for map and list parameters
the content-type will be automatically changed to multipart.

```elixir
defmodule Sample.SomeControllerTest do
  use Sample.ConnCase

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    {:ok, conn: conn}
  end

  test "create action", %{conn: conn} do
    params = Poison.encode!(%{data: %{attributes: @valid_attrs}})
    conn = post conn, "/some_resource", params

    ...
  end

  ...
end
```

### Pagination

JaSerializer provides page based pagination integration with
[Scrivener](https://github.com/drewolson/scrivener) or custom pagination
by passing your owns links in.

#### Custom

JaSerializer allows custom pagination via the `page` option. The `page` option
expects to receive a `Dict` with URL values for `first`, `next`, `prev`,
and `last`.

For example:

```elixir
page = [
  first: "http://example.com/api/v1/posts?page[cursor]=1&page[per]=20",
  prev: nil
  next: "http://example.com/api/v1/posts?page[cursor]=20&page[per]=20",
  last: "http://example.com/api/v1/posts?page[cursor]=60&page[per]=20"
]

# Direct call
MySerializer.format(collection, conn, page: page)

# In Phoenix Controller
render conn, model: collection, opts: [page: page]
```

#### Scrivener Integration

If you are using Scrivener for pagination, all you need to do is pass the
results of `paginate/2` to your serializer.

```elixir
page = MyRepo.paginate(MyModel, params.page)

# Direct call
MySerializer.format(page, conn, [])

# In Phoenix controller
render conn, model: page
```

When integrating with Scrivener the URLs generated will be based on the
`Plug.Conn`'s path. This can be overridden by passing in the `page[:base_url]`
option.

```elixir
render conn, model: page, opts: [page: [base_url: "http://example.com/foos"]]
```

*Note*: The resulting URLs will use the JSON-API recommended `page` query
param.

Example URL:
`http://example.com/v1/posts?page[page]=2&page[page_size]=50`


## Configuration

### Attribute & Relationship key format

By default keys are `dash-erized` as per the jsonapi.org recommendation, but
keys can be customized via config.

In your config.exs file:

```elixir
config :ja_serializer,
  key_format: :underscored
```

You may also pass a custom function that accepts 1 binary argument:

```elixir
defmodule MyStringModule do
  def camelize(key), do: key #...
end

config :ja_serializer,
  key_format: {:custom, MyStringModule, :camelize}
```

## Custom Attribute Value Formatters

When serializing attribute values more complex than string, numbers, atoms or
list of those things it is recommended to implement a custom formatter.

To implement a custom formatter:

```elixir
defimpl JaSerializer.Formatter, for: [MyStruct] do
  def format(struct), do: struct
end
```

## License

JaSerializer source code is released under Apache 2 License. Check LICENSE
file for more information.
