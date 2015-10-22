defmodule JaSerializer.Builder.IncludedTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      serializer: JaSerializer.Builder.IncludedTest.CommentSerializer,
      include: true
    has_one :author,
      serializer: JaSerializer.Builder.IncludedTest.PersonSerializer,
      include: true
  end

  defmodule DeprecatedArticalSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      include: JaSerializer.Builder.IncludedTest.CommentSerializer
  end

  defmodule PersonSerializer do
    use JaSerializer
    def type, do: "people"
    attributes [:name]
  end

  defmodule CommentSerializer do
    use JaSerializer
    def type, do: "comments"
    location "/comments/:id"
    attributes [:body]
    has_one :author,
      serializer: JaSerializer.Builder.IncludedTest.PersonSerializer,
      include: true
    has_many :comments,
      serializer: JaSerializer.Builder.IncludedTest.CommentSerializer,
      include: true
  end

  test "multiple levels of includes are respected" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    p2 = %TestModel.Person{id: "p2", first_name: "p2"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p2}
    c2 = %TestModel.Comment{id: "c2", body: "c2", author: p1}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1, c2]}

    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert "p1" in ids
    assert "p2" in ids
    assert "c1" in ids
    assert "c2" in ids

    assert [_,_,_,_] = includes

    # Formatted
    json = ArticleSerializer.format(a1)
    assert %{} = json[:data]
    assert [_,_,_,_] = json[:included]
  end

  test "duplicate models are not included twice" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p1}
    c2 = %TestModel.Comment{id: "c2", body: "c2", author: p1}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1, c2]}

    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert [_,_,_] = includes
    assert "p1" in ids
    assert "c1" in ids
    assert "c2" in ids

    # Formatted
    json = ArticleSerializer.format(a1)
    assert %{} = json[:data]
    assert [_,_,_] = json[:included]
  end

  test "specifying a serializer as the `include` option still works" do
    c1 = %TestModel.Comment{id: "c1", body: "c1"}
    a1 = %TestModel.Article{id: "a1", title: "a1", comments: [c1]}

    context = %{model: a1, conn: %{}, serializer: DeprecatedArticalSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert [_] = includes
    assert "c1" in ids

    # Formatted
    json = ArticleSerializer.format(a1)
    assert %{} = json[:data]
    assert [_] = json[:included]
  end
end
