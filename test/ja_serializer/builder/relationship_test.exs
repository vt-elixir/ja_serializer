defmodule JaSerializer.Builder.RelationshipTest do
  use ExUnit.Case
  alias JaSerializer.Builder.Relationship
  alias JaSerializer.Relationship.HasMany
  alias JaSerializer.Builder.RelationshipTest.CommentSerializer

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      serializer: CommentSerializer,
      include: true
  end

  defmodule CommentSerializer do
    use JaSerializer
    def id(comment, _conn), do: comment.comment_id
    def type, do: "comments"
    location "/comments/:id"
    attributes [:body]
  end

  defmodule FooSerializer do
    use JaSerializer
    has_many :bars,
             type: "bar",
             links: [
               self: "/foo/:id/relationships/bars",
               related: "/foo/:id/bars"
             ]

    has_one :baz, field: :baz_id, type: "baz"
    def bars(_,_), do: [1,2,3]
  end

  test "custom id def respected in relationship data" do
    c1 = %TestModel.CustomIdComment{comment_id: "c1", body: "c1"}
    c2 = %TestModel.CustomIdComment{comment_id: "c2", body: "c2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1, c2]}

    context = %{data: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    %JaSerializer.Builder.ResourceObject{
      relationships: [%JaSerializer.Builder.Relationship{:data => rel_data}]
    } = primary_resource

    assert [_,_] = rel_data

    ids = Enum.map(rel_data, &(&1.id))
    assert "c1" in ids
    assert "c2" in ids

    # Formatted
    json = JaSerializer.format(ArticleSerializer, a1)
    assert %{"relationships" => %{"comments" => comments}} = json["data"]
    assert [_, _] = comments["data"]

    formatted_ids = Enum.map(comments["data"], &(&1["id"]))
    assert "c1" in formatted_ids
    assert "c2" in formatted_ids
  end

  test "building a self link Relationship is possible along with the 'related'" do
    json = JaSerializer.format(FooSerializer, %{baz_id: 1, id: 1})
    rel_links = json["data"]["relationships"]["bars"]["links"]
    assert  "/foo/1/relationships/bars" = rel_links["self"]
    assert  "/foo/1/bars" = rel_links["related"]
  end

  test "building relationships from ids works" do
    json = JaSerializer.format(FooSerializer, %{baz_id: 1, id: 1})
    assert %{"relationships" => %{"bars" => bars, "baz" => baz}} = json["data"]
    assert baz["data"]["id"] == "1"
    assert [bar, _, _ ] = bars["data"]
    assert bar["id"] == "1"
  end

  test "identifiers are included if type passed in" do
    comments = %HasMany{
      type: "comment",
      data: [1,2,3]
    }
    context = %{conn: %{}, opts: []}
    rel = Relationship.build({:comments, comments}, context)
    assert [_ri1, _ri2, _ri3] = rel.data
  end

  test "identifiers are included if serializer is passed in and include is true" do
    comments = %HasMany{
      serializer: CommentSerializer,
      data: [1,2,3],
      include: true
    }
    context = %{conn: %{}, opts: []}
    rel = Relationship.build({:comments, comments}, context)
    assert [_ri1, _ri2, _ri3] = rel.data
  end

  test "identifiers are included if serializer is passed in & name is in the include param" do
    comments = %HasMany{
      serializer: CommentSerializer,
      data: [1,2,3],
      identifiers: :always
    }
    context = %{conn: %{}, opts: [include: [:comments]]}
    rel = Relationship.build({:comments, comments}, context)
    assert [_ri1, _ri2, _ri3] = rel.data
  end

  test "identifiers are included if serializer is passed in & name is in the identifiers param" do
    comments = %HasMany{
      serializer: CommentSerializer,
      data: [1,2,3],
      identifiers: :when_included # overridden
    }
    context = %{conn: %{}, opts: [identifiers: [comments: []]]}
    rel = Relationship.build({:comments, comments}, context)
    assert [_ri1, _ri2, _ri3] = rel.data
  end

  test "identifiers are included if the serializer is passed in & name is in include param & identifiers is when_included" do
    comments = %HasMany{
      serializer: CommentSerializer,
      data: [1,2,3],
      identifiers: :when_included
    }
    context = %{conn: %{}, opts: [include: [comments: []]]}
    rel = Relationship.build({:comments, comments}, context)
    assert [_ri1, _ri2, _ri3] = rel.data
  end

  test "identifiers are included if the serializer is passed in & name is not in include param & identifiers is always" do
    comments = %HasMany{
      serializer: CommentSerializer,
      data: [1,2,3],
      identifiers: :always
    }
    context = %{conn: %{}, opts: [include: [author: []]]}
    rel = Relationship.build({:comments, comments}, context)
    assert [_ri1, _ri2, _ri3] = rel.data
  end

  test "identifiers are not included if the serializer is passed in & name is not in include param & include is true & identifiers is when_included" do
    comments = %HasMany{
      serializer: CommentSerializer,
      identifiers: :when_included
    }
    context = %{conn: %{}, opts: [include: [:author]]}
    rel = Relationship.build({:comments, comments}, context)
    assert is_nil(rel.data)
  end

  test "identifiers are not included if the serializer is passed in, there are not in include params & indentifiers is when_included" do
    comments = %HasMany{
      serializer: CommentSerializer,
      identifiers: :when_included
    }
    context = %{conn: %{}, opts: []}
    rel = Relationship.build({:comments, comments}, context)
    assert rel.data == nil
  end

  test "skipping relationship building with `relationships: false`" do
    json = JaSerializer.format(FooSerializer, %{baz_id: 1, id: 1}, %{}, relationships: false)
    refute Map.has_key?(json["data"], "relationships")
  end
end
