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
       "first": "/articles/?page[number]=1&page[size]=10",
       "last": "/articles/?page[number]=5&page[size]=10",
       "next": "/articles/?page[number]=4&page[size]=10",
       "prev": "/articles/?page[number]=2&page[size]=10",
       "self": "/articles/?page[number]=3&page[size]=10"
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
    location("/articles/:id")
    attributes([:title])

    has_many(:comments,
      link: "/articles/:id/comments",
      serializer: CommentSerializer,
      include: true
    )

    has_one(:author,
      link: "/articles/:id/author",
      serializer: PersonSerializer,
      include: true
    )

    has_many(:likes,
      link: "/articles/:id/likes",
      serializer: LikeSerializer,
      include: true
    )

    has_one(:excerpt,
      link: "/articles/:id/excerpt",
      serializer: ExcerptSerializer,
      include: true
    )
  end

  defmodule PostSerializer do
    use JaSerializer, dsl: false
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.PersonSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.CommentSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.LikeSerializer
    alias JaSerializer.JsonApiSpec.CompoundDocumentTest.ExcerptSerializer

    def type, do: "articles"
    def links(_data, _conn), do: [self: "/articles/:id"]
    def attributes(article, _conn), do: Map.take(article, [:title])

    def relationships(article, _conn) do
      %{
        comments: %HasMany{
          links: [related: "/articles/:id/comments"],
          serializer: CommentSerializer,
          include: true,
          data: article.comments
        },
        author: %HasOne{
          links: [related: "/articles/:id/author"],
          serializer: PersonSerializer,
          include: true,
          data: article.author
        },
        likes: %HasMany{
          links: [related: "/articles/:id/likes"],
          serializer: LikeSerializer,
          include: true,
          data: article.likes
        },
        excerpt: %HasOne{
          links: [related: "/articles/:id/excerpt"],
          serializer: ExcerptSerializer,
          include: true,
          data: article.excerpt
        }
      }
    end
  end

  defmodule PersonSerializer do
    use JaSerializer
    def type, do: "people"
    location("/people/:id")
    attributes([:first_name, :last_name, :twitter])
  end

  defmodule CommentSerializer do
    use JaSerializer
    def type, do: "comments"
    location("/comments/:id")
    attributes([:body])
  end

  defmodule LikeSerializer do
    use JaSerializer
    def type, do: "likes"
    location("/likes/:id")
  end

  defmodule ExcerptSerializer do
    use JaSerializer
    def type, do: "excerpts"
    location("/excerpts/:id")
    attributes([:body])
  end

  setup do
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
      likes: []
    }

    page = %Scrivener.Page{
      entries: [article],
      page_number: 3,
      total_pages: 5,
      page_size: 10
    }

    conn = %Plug.Conn{
      query_params: %{},
      request_path: "/articles/"
    }

    {:ok, page: page, conn: conn}
  end

  test "it serializes properly via the DSL", %{page: page, conn: conn} do
    hashset = &Enum.into(&1, MapSet.new())

    results =
      JaSerializer.format(ArticleSerializer, page, conn, [])
      |> Poison.encode!()
      |> Poison.decode!(keys: :atoms)

    expected = Poison.decode!(@expected, keys: :atoms)

    assert results[:links] == expected[:links]
    assert hashset.(results[:included]) == hashset.(expected[:included])
    assert results[:data][:attributes] == expected[:data][:attributes]
    assert results[:data] == expected[:data]
    assert Map.delete(results, :included) == Map.delete(expected, :included)
  end

  test "it serializes properly via the behaviour", %{page: page, conn: conn} do
    hashset = &Enum.into(&1, MapSet.new())

    results =
      JaSerializer.format(PostSerializer, page, conn, [])
      |> Poison.encode!()
      |> Poison.decode!(keys: :atoms)

    expected = Poison.decode!(@expected, keys: :atoms)

    assert results[:links] == expected[:links]
    assert hashset.(results[:included]) == hashset.(expected[:included])
    assert results[:data][:attributes] == expected[:data][:attributes]
    assert results[:data] == expected[:data]
    assert Map.delete(results, :included) == Map.delete(expected, :included)
  end

  test "it does not return any relationships when relationships opt is false",
       %{page: page, conn: conn} do
    results =
      JaSerializer.format(PostSerializer, page, conn, relationships: false)
      |> Poison.encode!()
      |> Poison.decode!(keys: :atoms)

    refute results[:included]
    refute results[:data][:relationships]
  end
end
