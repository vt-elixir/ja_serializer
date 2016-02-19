defmodule JaSerializer.Builder.RelationshipTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      serializer: JaSerializer.Builder.RelationshipTest.CommentSerializer,
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
    has_many :bars, type: "bar"
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
    json = ArticleSerializer.format(a1)
    assert %{relationships: %{"comments" => comments}} = json[:data]
    assert [_,_] = comments[:data]

    formatted_ids = Enum.map(comments[:data], &(&1.id))
    assert "c1" in formatted_ids
    assert "c2" in formatted_ids
  end

  test "building relationships from ids works" do
    json = FooSerializer.format(%{baz_id: 1, id: 1})
    assert %{relationships: %{"bars" => bars, "baz" => baz}} = json[:data]
    assert baz.data.id == "1"
    assert [bar, _, _ ] = bars.data
    assert bar.id == "1"
  end
end
