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
    attributes [:title]
    has_one :author,
      link: "/articles/:id/author",
      type: "people"
    has_many :comments,
      link: "/articles/:id/comments"
    has_many :likes,
      type: "like"
    has_one :excerpt,
      type: "excerpt"
  end

  test "it serializes properly" do
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

    results = article
              |> ArticleSerializer.format(%{}, meta: %{copyright: 2015})
              |> Poison.encode!
              |> Poison.decode!(keys: :atoms)

    assert results == Poison.decode!(@expected, keys: :atoms)
  end
end
