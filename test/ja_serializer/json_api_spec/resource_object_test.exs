defmodule JaSerializer.JsonApiSpec.ResourceObjectTest do
  use ExUnit.Case

  @expected """
  {
    "jsonapi": {
      "version": "1.0"
    },
    "meta": { "copyright": 2015 },
    "data": {
      "type": "articles",
      "id": "1",
      "attributes": {
        "title": "Rails is Omakase"
      },
      "meta": {"search_match": "Omakase"},
      "relationships": {
        "author": {
          "links": {
            "related": "/articles/1/author"
          },
          "data": { "type": "people", "id": "9" }
        },
        "comments": {
          "links": {
            "related": "/articles/1/comments"
          }
        },
        "likes": {
          "data": []
        },
        "excerpt": {
          "data": null
        }
      }
    }
  }
  """

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes([:title])

    has_one(:author,
      link: "/articles/:id/author",
      type: "people"
    )

    has_many(:comments,
      link: "/articles/:id/comments"
    )

    has_many(:likes,
      type: "like"
    )

    has_one(:excerpt,
      type: "excerpt"
    )

    def meta(_article, _conn), do: %{search_match: "Omakase"}
  end

  defmodule PostSerializer do
    use JaSerializer, dsl: false
    def type, do: "articles"
    def meta(_article, _conn), do: %{search_match: "Omakase"}
    def attributes(post, _conn), do: %{title: post.title}

    def relationships(post, _conn) do
      %{
        author: %HasOne{
          links: [related: "/articles/:id/author"],
          type: "people",
          data: post.author
        },
        comments: %HasMany{links: [related: "/articles/:id/comments"]},
        likes: %HasMany{type: "like", data: post.likes},
        excerpt: %HasOne{type: "excerpt"}
      }
    end
  end

  setup do
    author = %TestModel.Person{
      id: 9,
      first_name: "Dan",
      last_name: "Ghebhart",
      twitter: "dgeb"
    }

    article = %TestModel.Article{
      id: 1,
      title: "Rails is Omakase",
      author: author,
      comments: [],
      likes: []
    }

    {:ok, author: author, article: article}
  end

  test "it serializes properly using DSL", %{article: article} do
    results =
      JaSerializer.format(ArticleSerializer, article, %{},
        meta: %{copyright: 2015}
      )
      |> Poison.encode!()
      |> Poison.decode!(keys: :atoms)

    assert results == Poison.decode!(@expected, keys: :atoms)
  end

  test "it serializes properly using behaviour", %{article: article} do
    results =
      JaSerializer.format(PostSerializer, article, %{}, meta: %{copyright: 2015})
      |> Poison.encode!()
      |> Poison.decode!(keys: :atoms)

    assert results == Poison.decode!(@expected, keys: :atoms)
  end
end
