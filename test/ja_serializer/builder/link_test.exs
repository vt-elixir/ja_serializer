defmodule JaSerializer.Builder.LinkTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    has_many :comments,
      serializer: JaSerializer.Builder.LinkTest.CommentSerializer,
      link: "comments?article_id=:id"
  end

  defmodule PostSerializer do
    use JaSerializer

    has_many :comments,
      serializer: JaSerializer.Builder.LinkTest.CommentSerializer,
      link: "articles/:id/comments"
  end

  defmodule CommentSerializer do
    use JaSerializer
  end

  test "id in url path" do
    c1 = %TestModel.Comment{id: "c1", body: "c1"}
    c2 = %TestModel.Comment{id: "c2", body: "c2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1, c2]}

    context = %{data: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    %JaSerializer.Builder.ResourceObject{
      relationships: [%JaSerializer.Builder.Relationship{:links => [%JaSerializer.Builder.Link{href: href}]}]
    } = primary_resource

    assert href == "comments?article_id=a1"
  end

  test "id in query params" do
    c1 = %TestModel.Comment{id: "c1", body: "c1"}
    c2 = %TestModel.Comment{id: "c2", body: "c2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1, c2]}

    context = %{data: a1, conn: %{}, serializer: PostSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    %JaSerializer.Builder.ResourceObject{
      relationships: [%JaSerializer.Builder.Relationship{:links => [%JaSerializer.Builder.Link{href: href}]}]
    } = primary_resource

    assert href == "articles/a1/comments"
  end
end
