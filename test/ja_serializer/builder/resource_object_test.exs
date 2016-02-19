defmodule JaSerializer.Builder.ResourceObjectTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer

    def type, do: "articles"
    attributes [:title, :body]
  end

  test "single resource object built correctly" do
    a1 = %TestModel.Article{id: "a1", title: "a1", body: "a1"}

    context = %{data: a1, conn: %{}, serializer: ArticleSerializer, opts: []}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    assert %{id: "a1", attributes: attributes} = primary_resource
    assert [_,_] = attributes

    # Formatted
    json = ArticleSerializer.format(a1)

    assert %{attributes: attributes} = json[:data]
    fields = Map.keys(attributes)
    assert "title" in fields
    assert "body" in fields
  end

  test "sparse fieldset returns only specified fields" do
    a1 = %TestModel.Article{id: "a1", title: "a1", body: "a1"}
    fields = %{"articles" => "title"}

    context = %{data: a1, conn: %{}, serializer: ArticleSerializer, opts: [fields: fields]}
    primary_resource = JaSerializer.Builder.ResourceObject.build(context)

    assert %{id: "a1", attributes: attributes} = primary_resource
    assert [_] = attributes

    # Formatted
    json = ArticleSerializer.format(a1, %{}, fields: fields)

    assert %{attributes: attributes} = json[:data]
    fields = Map.keys(attributes)
    assert "title" in fields
    refute "body" in fields
  end
end
