defmodule JaSerializer.SerializerTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer
    attributes([:title])
    attributes([:body])
    has_many(:comments)
  end

  defmodule ArticleView do
    use JaSerializer
    attributes([:title, :body])
    has_many(:comments)

    def attributes(article, conn) do
      super(article, conn) |> Map.take([:title])
    end

    def comments(_a, _c), do: [:bar]
  end

  defmodule CustomArticle do
    use JaSerializer

    def type, do: "article"

    def attributes(article, _conn) do
      Map.take(article, [:body])
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
    article = %TestModel.Article{title: "test", body: "test"}

    assert @serializer.attributes(article, %{}) == %{
             title: "test",
             body: "test"
           }

    assert @view.attributes(article, %{}) == %{title: "test"}
    assert @custom.attributes(article, %{}) == %{body: "test"}
  end

  test "has_many should define an overridable relationship data function" do
    article = %TestModel.Article{title: "test", body: "test", comments: [:foo]}
    assert @serializer.comments(article, %{}) == [:foo]
    assert @view.comments(article, %{}) == [:bar]
  end

  test "it should pluralize the type when declared in config" do
    Application.put_env(:ja_serializer, :pluralize_types, true)

    defmodule NewArticleSerializer do
      use JaSerializer
      attributes([:title, :body])
      has_many(:comments)
    end

    assert NewArticleSerializer.type() == "new-articles"

    Application.delete_env(:ja_serlializer, :pluralized_types)
  end
end
