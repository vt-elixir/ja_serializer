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
    has_many :tags,
      serializer: JaSerializer.Builder.IncludedTest.TagSerializer
  end

  defmodule DeprecatedArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      include: JaSerializer.Builder.IncludedTest.CommentSerializer
  end

  defmodule OptionalIncludeArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title]
    has_many :comments,
      serializer: JaSerializer.Builder.IncludedTest.CommentSerializer
    has_one :author,
      serializer: JaSerializer.Builder.IncludedTest.PersonSerializer
    has_many :tags,
      serializer: JaSerializer.Builder.IncludedTest.TagSerializer
  end

  defmodule PersonSerializer do
    use JaSerializer
    def type, do: "people"
    attributes [:first_name, :last_name]
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
      serializer: JaSerializer.Builder.IncludedTest.PersonSerializer,
      include: true
    has_many :comments,
      serializer: JaSerializer.Builder.IncludedTest.CommentSerializer,
      include: true
    has_many :tags,
      serializer: JaSerializer.Builder.IncludedTest.TagSerializer
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

    context = %{model: a1, conn: %{}, serializer: DeprecatedArticleSerializer, opts: []}
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

  # Optional includes
  test "only specified relationships serialized when 'include' option defined" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    p2 = %TestModel.Person{id: "p2", first_name: "p2"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p2}
    c2 = %TestModel.Comment{id: "c2", body: "c2", author: p1}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1, c2]}

    opts = [include: [author: []]]
    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: opts}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert [_] = ids
    assert "p1" in ids

    # Formatted
    json = ArticleSerializer.format(a1, %{}, include: "author")
    assert %{} = json[:data]
    assert [_] = json[:included]
  end

  test "2nd level includes are serialized correctly" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    p2 = %TestModel.Person{id: "p2", first_name: "p2"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p2}
    c2 = %TestModel.Comment{id: "c2", body: "c2", author: p1}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1, c2]}

    opts = [include: [author: [], comments: [author: []]]]
    context = %{model: a1, conn: %{}, serializer: OptionalIncludeArticleSerializer, opts: opts}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert [_,_,_,_] = ids
    assert "p1" in ids
    assert "p2" in ids
    assert "c1" in ids
    assert "c2" in ids

    # Formatted
    json = OptionalIncludeArticleSerializer.format(a1, %{}, include: "author,comments.author")
    assert %{} = json[:data]
    assert [_,_,_,_] = json[:included]
  end

  test "sibling includes are serialized correctly" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    t1 = %TestModel.Tag{id: "t1", tag: "t1"}
    t2 = %TestModel.Tag{id: "t2", tag: "t2"}
    c1 = %TestModel.Comment{id: "c1", body: "c1", author: p1, tags: [t2]}
    a1 = %TestModel.Article{id: "a1", title: "a1", author: p1, comments: [c1], tags: [t1]}

    opts = [include: [tags: [], comments: [author: [], tags: []]]]
    context = %{model: a1, conn: %{}, serializer: OptionalIncludeArticleSerializer, opts: opts}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    ids = Enum.map(includes, &(&1.id))
    assert [_,_,_,_] = ids
    assert "p1" in ids
    assert "c1" in ids
    assert "t1" in ids
    assert "t2" in ids

    # Formatted
    json = OptionalIncludeArticleSerializer.format(a1, %{}, include: "tags,comments.author,comments.tags")
    assert %{} = json[:data]
    assert [_,_,_,_] = json[:included]
  end

  test "sparse fieldset returns only specified fields" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1", last_name: "p1"}
    a1 = %TestModel.Article{id: "a1", title: "a1", body: "a1", author: p1}

    fields = %{"articles" => "title", "people" => "first_name"}
    opts = [fields: fields]
    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: opts}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    assert %{id: "a1", attributes: attributes} = primary_resource
    assert [_] = attributes

    assert [person] = includes
    assert [_] = person.attributes

    # Formatted
    json = ArticleSerializer.format(a1, %{}, fields: fields)
    assert %{attributes: formatted_attrs} = json[:data]
    article_attrs = Map.keys(formatted_attrs)
    assert [_] = article_attrs
    assert "title" in article_attrs
    refute "body" in article_attrs

    assert [formatted_person] = json[:included]
    person_attrs = Map.keys(formatted_person[:attributes])
    assert [_] = person_attrs
    assert "first-name" in person_attrs
    refute "last-name" in person_attrs
  end

  test "sparse fieldset restricts on a per-type basis only" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1", last_name: "p1"}
    a1 = %TestModel.Article{id: "a1", title: "a1", body: "a1", author: p1}

    fields = %{"articles" => "title"}
    opts = [fields: fields]
    context = %{model: a1, conn: %{}, serializer: ArticleSerializer, opts: opts}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)
    includes = JaSerializer.Builder.Included.build(context, primary_resource)

    assert [person] = includes
    assert [_,_] = person.attributes

    # Formatted
    json = ArticleSerializer.format(a1, %{}, fields: fields)
    assert [formatted_person] = json[:included]
    person_attrs = Map.keys(formatted_person[:attributes])
    assert [_,_] = person_attrs
    assert "first-name" in person_attrs
    assert "last-name" in person_attrs
  end
end
