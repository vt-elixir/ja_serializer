JaSerializer
============

jsonapi.org formatting of Elixir data structures suitable for serialization by
libraries such as Poison.

Warning: This is Alpha software and subject to breaking changes.

## Documentation

See [documentation](http://hexdocs.pm/ja_serializer/) on hexdoc for full
serialization and usage details.


## Serializer Behaviour and DSL:

```elixir
defmodule MyApp.ArticleSerializer do
  use JaSerializer

  location: "/articles/:id"
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

## Direct Usage

```elixir
model
|> MyApp.ArticleSerializer.format(conn)
|> Poison.encode!
```

## Relax Usage

See [Relax](https://github.com/AgilionApps/relax) documentation for building
fully compatable jsonapi.org APIs with Plug.

## Phoenix Usage

Simply `use JaSerializer.PhoenixView` in your view (or in the Web module) and
define your serializer as above.

The `render("index.json", data)` and `render("show.json", data)` are defined
for you. You can just call render as normal from your controller.

```elixir
defmodule PhoenixExample.ArticlesView do
  use PhoenixExample.Web, :view
  use JaSerializer.PhoenixView # Or use in web/web.ex

  attributes [:title]
  #has_many, etc.
end

defmodule PhoenixExample.ArticlesController do
  use PhoenixExample.Web, :controller

  def index(conn, _params) do
    render conn, model: PhoenixExample.Repo.all(PhoenixExample.Article)
  end

  def show(conn, params) do
    render conn, model: PhoenixExample.Repo.get(PhoenixExample.Article, params[:id])
  end
end
```

## Configuration

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

## License

JaSerializer source code is released under Apache 2 License. Check LICENSE 
file for more information.
