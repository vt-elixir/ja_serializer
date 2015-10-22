defmodule JaSerializer.JsonApiSpec.CompoundDocumentTest do
  use ExUnit.Case

  @expected """
  {
    "jsonapi": {"version": "1.0"},
    "data": [{
      "type": "articles",
      "id": "1",
      "attributes": {
        "title": "JSON API paints my bikeshed!"
      },
      "links": {
       "self": "/articles/1"
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
          },
          "data": [
            { "type": "comments", "id": "5" },
            { "type": "comments", "id": "12" }
          ]
        },
        "likes": {
          "links": {
            "related": "/articles/1/likes"
          },
          "data": []
        },
        "excerpt": {
          "links": {
            "related": "/articles/1/excerpt"
          },
          "data": null
        }
      }
    }],
    "links": {
       "first": "/articles/?page[page]=1&page[page_size]=10",
       "last": "/articles/?page[page]=5&page[page_size]=10",
       "next": "/articles/?page[page]=4&page[page_size]=10",
       "prev": "/articles/?page[page]=2&page[page_size]=10",
       "self": "/articles/?page[page]=3&page[page_size]=10"
     },
    "included": [{
      "type": "people",
      "id": "9",
      "attributes": {
        "first-name": "Dan",
        "last-name": "Gebhardt",
        "twitter": "dgeb"
      },
      "links": {
        "self": "/people/9"
      }
    }, {
      "type": "comments",
      "id": "5",
      "attributes": {
        "body": "First!"
      },
      "links": {
        "self": "/comments/5"
      }
    }, {
      "type": "comments",
      "id": "12",
      "attributes": {
        "body": "I like XML better"
      },
      "links": {
        "self": "/comments/12"
      }
    }]
  }
  """

  defmodule ArticleSerializer do
    use JaSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.PersonSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.CommentSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.LikeSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.ExcerptSerializer

    def type, do: "articles"
    location "/articles/:id"
    attributes [:title]
    has_many :comments,
      link: "/articles/:id/comments",
      serializer: CommentSerializer,
      include: true
    has_one :author,
      link: "/articles/:id/author",
      serializer: PersonSerializer,
      include: true
    has_many :likes,
      link: "/articles/:id/likes",
      serializer: LikeSerializer,
      include: true
    has_one :excerpt,
      link: "/articles/:id/excerpt",
      serializer: ExcerptSerializer,
      include: true
  end

  defmodule PersonSerializer do
    use JaSerializer
    def type, do: "people"
    location "/people/:id"
    attributes [:first_name, :last_name, :twitter]
  end

  defmodule CommentSerializer do
    use JaSerializer
    def type, do: "comments"
    location "/comments/:id"
    attributes [:body]
  end

  defmodule LikeSerializer do
    use JaSerializer
    def type, do: "likes"
    location "/likes/:id"
  end

  defmodule ExcerptSerializer do
    use JaSerializer
    def type, do: "excerpts"
    location "/excerpts/:id"
    attributes [:body]
  end

  test "it serializes properly" do
    author = %TestModel.Person{
      id: 9,
      first_name: "Dan",
      last_name: "Gebhardt",
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
      title: "JSON API paints my bikeshed!",
      author: author,
      comments: [c1, c2],
      likes: [],
    }

    model = %Scrivener.Page{
      entries: [article],
      page_number: 3,
      total_pages: 5,
      page_size: 10
    }

    conn = %Plug.Conn{
      query_params: %{},
      request_path: "/articles/"
    }

    results = ArticleSerializer.format(model, conn, [])
              |> Poison.encode!
              |> Poison.decode!(keys: :atoms)

    expected = Poison.decode!(@expected, keys: :atoms)

    assert results[:links] == expected[:links]
    assert results[:included] == expected[:included]
    assert results[:data][:attributes] == expected[:data][:attributes]
    assert results[:data] == expected[:data]
    assert results == expected
  end
end
