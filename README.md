JaSerializer
============

jsonapi.org formatting of Elixir data structures suitable for serialization by
libraries such as Poison.

## TODO:

This software is not ready for consumption.

* Easy integration into Pheonix.
* Easy integration into Relax.
* Extensibility of serialization behavior using Protocols.
* Support of all required JSON API 1.0 features.

## Serializer DSL:

```elixir
defmodule MyApp.ArticleSerializer do
  use JaSerializer

  serialize "articles" do
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

