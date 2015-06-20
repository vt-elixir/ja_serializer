defmodule JaSerializer.JsonApiSpec.ResourceObjectTest do
  use ExUnit.Case

  @expected """
  {
    "jsonapi": {
      "version": "1.0"
    },
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
        }
      }
    }
  }
  """

  defmodule ArticleSerializer do
    use JaSerializer

    serialize "articles" do
      attributes [:title]
      has_one :author,
        link: "/aricles/:id/author",
        type: "people"
    end
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
      comments: []
    }

    results = ArticleSerializer.format(article)

    assert results == Poison.decode!(@expected)
  end
end
