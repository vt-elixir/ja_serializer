defmodule JaSerializer.Builder.IncludedTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    serialize "articles" do
      attributes [:title]
      has_many :comments,
        include: JaSerializer.Builder.IncludedTest.CommentSerializer
      has_one :author,
        include: JaSerializer.Builder.IncludedTest.PersonSerializer
    end
  end

  defmodule PersonSerializer do
    use JaSerializer
    serialize "people" do
      attributes [:name]
    end
  end

  defmodule CommentSerializer do
    use JaSerializer
    serialize "comments" do
      location "/comments/:id"
      attributes [:body]
      has_one :author,
        include: JaSerializer.Builder.IncludedTest.PersonSerializer
      has_many :comments,
        include: JaSerializer.Builder.IncludedTest.CommentSerializer
    end
  end

  test "multiple levels of includes are respected" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    p2 = %TestModel.Person{id: "p2", first_name: "p2"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p2}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1] }

    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert "p1" in ids
    assert "p2" in ids
    assert "c1" in ids

    assert [_,_,_] = includes
  end

  test "duplicate models are not included twice" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p1}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1]}

    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert [_,_] = includes
    assert "p1" in ids
    assert "c1" in ids
  end
end
