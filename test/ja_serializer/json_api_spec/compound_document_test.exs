defmodule JaSerializer.JsonApiSpec.CompoundDocumentTest do
  use ExUnit.Case

  @expected """
  {
    "data": [{
      "type": "articles",
      "id": "1",
      "attributes": {
        "title": "JSON API paints my bikeshed!"
      },
      "links": {
        "self": "http://example.com/articles/1"
      },
      "relationships": {
        "author": {
          "links": {
            "self": "http://example.com/articles/1/relationships/author",
            "related": "http://example.com/articles/1/author"
          },
          "data": { "type": "people", "id": "9" }
        },
        "comments": {
          "links": {
            "self": "http://example.com/articles/1/relationships/comments",
            "related": "http://example.com/articles/1/comments"
          },
          "data": [
            { "type": "comments", "id": "5" },
            { "type": "comments", "id": "12" }
          ]
        }
      }
    }],
    "included": [{
      "type": "people",
      "id": "9",
      "attributes": {
        "first-name": "Dan",
        "last-name": "Gebhardt",
        "twitter": "dgeb"
      },
      "links": {
        "self": "http://example.com/people/9"
      }
    }, {
      "type": "comments",
      "id": "5",
      "attributes": {
        "body": "First!"
      },
      "links": {
        "self": "http://example.com/comments/5"
      }
    }, {
      "type": "comments",
      "id": "12",
      "attributes": {
        "body": "I like XML better"
      },
      "links": {
        "self": "http://example.com/comments/12"
      }
    }]
  }
  """

  defmodule ArticleSerializer do
    use JaSerializer
    serialize "articles" do
      attributes [:title]
      has_one :author,
        link: "/articles/:id/author",
        include: PersonSerializer
      has_many :comments,
        link: "/articles/:id/comments",
        include: CommentSerializer
    end
  end

  defmodule PersonSerializer do
    use JaSerializer
    serialize "people" do
      attributes [:first_name, :last_name, :twitter]
    end
  end

  defmodule CommentSerializer do
    use JaSerializer
    serialize "comments" do
      attributes [:body]
    end
  end

  test "it serializes properly" do
    author = %TestModel.Person{
      id: 9,
      first_name: "Dan",
      last_name: "Ghebhart",
      twitter: "dgeb"
    }

    c1 = %TestModel.Comment{
      id: 5,
      body: "First!"
    }

    c2 = %TestModel.Comment{
      id: 12,
      body: "I like XML better"
    }

    article = %TestModel.Article{
      id: 1,
      title: "Rails is Omakase",
      author: author,
      comments: [c1, c2]
    }

    results = ArticleSerializer.format(article)

    assert results == @expected
  end
end
