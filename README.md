JaSerializer
============

jsonapi.org formatting of Elixir data structures suitable for serialization by
libraries such as Poison.

Warning: This software is not yet ready for consumption.

## TODO:

* Easy integration into Pheonix.
* Easy integration into Relax.
* Support of all required JSON API 1.0 features.
* Specs and documentation
* Edgecase/unit tests
* Pagination, meta and advanced links.

## Serializer DSL:

```elixir
defmodule MyApp.ArticleSerializer do
  use JaSerializer

  serialize "articles" do
    location: "/articles/:id"

    attributes [:title, :tags, :body]

    has_one :author,
      link: "/articles/:id/author",
      include: PersonSerializer

    has_many :comments,
      link: "/articles/:id/comments",
      include: CommentSerializer
  end

  def comments(model, _conn) do
    Comment.for_article(model)
  end
end
```

## Usage

```elixir
model
|> MyApp.ArticleSerializer.format(conn)
|> Poison.encode!
```


## License

JaSerializer source code is released under Apache 2 License. Check LICENSE file for more information.
