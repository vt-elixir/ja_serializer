defmodule JaSerializer.SerializerTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer.Serializer
    attributes [:title, :body]
  end

  defmodule ArticleView do
    use JaSerializer.Serializer
    attributes [:title, :body]

    def attributes(model, conn) do
      super(model, conn) |> Dict.take([:title])
    end
  end

  defmodule CustomArticle do
    use JaSerializer.Serializer

    def type, do: "article"

    def attributes(model, _conn) do
      Map.take(model, [:body])
    end
  end

  @serializer ArticleSerializer
  @view ArticleView
  @custom CustomArticle

  test "it should determine the type" do
    assert @serializer.type == "article"
    assert @view.type == "article"
    assert @custom.type == "article"
  end

  test "it should return the attributes" do
    model = %TestModel.Article{title: "test", body: "test"}

    assert @serializer.attributes(model, %{}) == %{
      title: "test",
      body: "test"
    }

    assert @view.attributes(model, %{}) == %{title: "test"}
    assert @custom.attributes(model, %{}) == %{body: "test"}
  end
end
