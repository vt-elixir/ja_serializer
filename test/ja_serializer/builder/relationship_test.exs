defmodule JaSerializer.Builder.RelationshipTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      include: JaSerializer.Builder.RelationshipTest.CommentSerializer
  end

  defmodule CommentSerializer do
    use JaSerializer
    def id(model, _conn), do: model.comment_id
    def type, do: "comments"
    location "/comments/:id"
    attributes [:body]
  end

  test "custom id def respected in relationship data" do
    c1 = %TestModel.CustomIdComment{comment_id: "c1", body: "c1"}
    c2 = %TestModel.CustomIdComment{comment_id: "c2", body: "c2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1, c2]}

    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
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
end
