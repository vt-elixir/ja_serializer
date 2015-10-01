defmodule JaSerializer.Builder.IncludedTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      include: JaSerializer.Builder.IncludedTest.CommentSerializer
    has_one :author,
      include: JaSerializer.Builder.IncludedTest.PersonSerializer,
      default: true
    has_many :tags,
      include: JaSerializer.Builder.IncludedTest.TagSerializer,
      default: false
  end

  defmodule PersonSerializer do
    use JaSerializer
    def type, do: "people"
    attributes [:name]
  end

  defmodule TagSerializer do
    use JaSerializer
    def type, do: "tags"
    attributes [:tag]
  end

  defmodule CommentSerializer do
    use JaSerializer
    def type, do: "comments"
    location "/comments/:id"
    attributes [:body]
    has_one :author,
      include: JaSerializer.Builder.IncludedTest.PersonSerializer
    has_many :comments,
      include: JaSerializer.Builder.IncludedTest.CommentSerializer
  end

  setup do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    p2 = %TestModel.Person{id: "p2", first_name: "p2"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p2}
    c2 = %TestModel.Comment{id: "c2", body: "c2", author: p1}
    t1 = %TestModel.Tag{id: "t1", tag: "t1"}
    t2 = %TestModel.Tag{id: "t2", tag: "t2"}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1, c2], tags: [t1, t2]}

    {:ok, a1: a1}
  end

  test "multiple levels of relationshipt are respected, w/o duplicates", c do
    context = %{model: c[:a1], conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert "p1" in ids
    assert "p2" in ids
    assert "c1" in ids
    assert "c2" in ids

    assert [_,_,_,_] = includes

    # Formatted
    json = ArticleSerializer.format(c[:a1])
    assert %{} = json[:data]
    assert [_,_,_,_] = json[:included]
  end

  test "passing an include param restricts to requested relationships", c do
    context = %{model: c[:a1], conn: %{}, serializer: ArticleSerializer, opts: [
      include: ["tags"]
    ]}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert "t1" in ids
    assert "t2" in ids
    refute "c1" in ids
    refute "p1" in ids

    assert [_,_] = includes

    
    json = ArticleSerializer.format(c[:a1], %{}, include: ["tags"])
    assert %{} = json[:data]
    assert [_,_] = json[:included]
  end

end
