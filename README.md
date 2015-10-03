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
    include: PersonSerializer,
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

### Direct Usage

```elixir
model
|> MyApp.ArticleSerializer.format(conn)
|> Poison.encode!
```

#### Pagination Usage

Pass a `page` map with keys `page_number`, `total_pages` and `page_size` to the format method.

```elixir
model
|> MyApp.ArticleSerializer.format(conn, %{page: %{page_number: 3, total_pages: 5, page_size: 10}})
|> Poison.encode!
```

Or you could use the [scrivener library](https://github.com/drewolson/scrivener) and pass the page
as a parameter

```elixir
page = MyApp.Person |> MyApp.Repo.paginate(page: 2, page_size: 5)
MyApp.ArticleSerializer.format(page.entries, conn, page)
|> Poison.encode!
```

### Relax Usage

See [Relax](https://github.com/AgilionApps/relax) documentation for building
fully compatable jsonapi.org APIs with Plug.

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
end

defmodule PhoenixExample.ArticlesView do
  use PhoenixExample.Web, :view
  use JaSerializer.PhoenixView # Or use in web/web.ex

  attributes [:title]
  #has_many, etc.
end
```

#### Pagination Usage

Pass a page `map` with keys `page_number`, `total_pages` and `page_size` in a `opts` map.

```elixir
  def index(conn, _params) do
    page = %{page_number: 3, total_pages: 5, page_size: 10}
    render conn, model: PhoenixExample.Repo.all(PhoenixExample.Article), opts: %{page: page}
  end
```

Or you could use the [scrivener library](https://github.com/drewolson/scrivener) and pass the page
as a parameter

```elixir
  def index(conn, _params) do
    page = MyApp.Article |> MyApp.Repo.paginate(page: 2, page_size: 5)
    render conn, model: page.entries, opts: %{page: page}
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

When serializing attribute values more complex then string, numbers, atoms or
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
