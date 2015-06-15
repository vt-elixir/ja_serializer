JaSerializer
============

jsonapi.org formatting of Elixir data structures suitable for serialization by
libraries such as Poison.

## Required Goals

* Serialization of Ecto models.
* Easy integration into Pheonix.
* Easy integration into Relax.
* Extensibility of serialization behavior using Protocols.
* Support of all required JSON API 1.0 features.

## Optional Features

* Serialization of other maps, structs, and other data structures.

## Desired DSL:

### Serializer definition

```elixir
defmodule MyApp.ArticleSerializer do
  use JaSerializer

  serialize "article" do
    id alias: :url
    attributes [:title, :excerpt, :body, :tags]

    has_many :authors, type: "user", link: "" | fn() {}
  end
end
```

