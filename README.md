JaSerializer
============

jsonapi.org formatting of Elixir data structures suitable for serialization by
libraries such as Poison.

Warning: This is Alpha software and subject to breaking changes.

## TODO:

* Easy integration into Pheonix.
* Easy integration into Relax.
* Support of all required JSON API 1.0 features.
* Type Specs
* Edgecase/unit tests
* Pagination, meta and advanced links.

## Serializer DSL:

```elixir
defmodule MyApp.ArticleSerializer do
  use JaSerializer

  serialize "articles" do
    location: "/articles/:id"

    attributes [:title, :tags, :body, :excerpt]

    has_one :author,
      include: PersonSerializer,
      field: :authored_by

    has_many :comments,
      link: "/articles/:id/comments",
  end

  def comments(model, _conn) do
    Comment.for_article(model)
  end

  def excerpt(article, _conn) do
    [first | _ ] = String.split(article.body, ".")
    first
  end
end
```

## Usage

```elixir
model
|> MyApp.ArticleSerializer.format(conn)
|> Poison.encode!
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

JaSerializer source code is released under Apache 2 License. Check LICENSE file for more information.
