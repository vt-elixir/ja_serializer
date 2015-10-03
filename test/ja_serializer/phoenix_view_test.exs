defmodule JaSerializer.PhoenixViewTest do
  use ExUnit.Case

  defmodule PhoenixExample.ArticleView do
    use JaSerializer.PhoenixView
    attributes [:title]
    location "/api/articles"
  end

  @view PhoenixExample.ArticleView

  setup do
    m1 = %TestModel.Article{id: 1, title: "article one"}
    m2 = %TestModel.Article{id: 2, title: "article two"}
    {:ok, m1: m1, m2: m2}
  end

  defmodule Page do
    defstruct [page_number: 3, total_pages: 5, page_size: 10]
  end

  test "render conn, index.json, model: model", c do
    json = @view.render("index.json", conn: %{}, model: [c[:m1], c[:m2]])
    assert [a1, _a2] = json[:data]
    assert Dict.has_key?(a1, :id)
    assert Dict.has_key?(a1, :attributes)
  end

  test "render conn, index.json, articles: models", c do
    json = @view.render("index.json", conn: %{}, articles: [c[:m1], c[:m2]])
    assert [a1, _a2] = json[:data]
    assert Dict.has_key?(a1, :id)
    assert Dict.has_key?(a1, :attributes)
  end

  test "render conn, index.json, model: model with pagination", c do
    json = @view.render("index.json", conn: %{}, model: [c[:m1], c[:m2]], opts: %{page: %Page{}})
    assert [a1, _a2] = json[:data]
    assert Dict.has_key?(a1, :id)
    assert Dict.has_key?(a1, :attributes)
    assert Dict.has_key?(json, :links)
  end

  test "render conn, show.json, data: model", c do
    json = @view.render("index.json", conn: %{}, data: c[:m1])
    assert Dict.has_key?(json[:data], :id)
    assert Dict.has_key?(json[:data], :attributes)
  end

  test "render conn, show.json, article: model", c do
    json = @view.render("index.json", conn: %{}, article: c[:m1])
    assert Dict.has_key?(json[:data], :id)
    assert Dict.has_key?(json[:data], :attributes)
  end
end
