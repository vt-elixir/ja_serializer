defmodule JaSerializer.SerializerTest do
  use ExUnit.Case

  defmodule ArticleSerializer do
    use JaSerializer.Serializer
    attributes [:title]
  end

  defmodule AuthorView do
    use JaSerializer.Serializer
    attributes [:name]
  end

  defmodule CustomJsonMaker do
    use JaSerializer.Serializer
    def type, do: "comment"
    attributes [:name]
  end

  @serializer ArticleSerializer
  @view AuthorView
  @custom CustomJsonMaker

  test "it should determine the type" do
    assert @serializer.type == "article"
    assert @view.type == "author"
    assert @custom.type == "comment"
  end
end
