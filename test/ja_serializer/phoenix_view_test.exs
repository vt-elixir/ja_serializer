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

  test "render conn, index.json-api, data: data", c do
    json = @view.render("index.json-api", conn: %{}, data: [c[:m1], c[:m2]])
    assert [a1, _a2] = json["data"]
    assert Dict.has_key?(a1, "id")
    assert Dict.has_key?(a1, "attributes")
  end

  # This should be deprecated in the future
  test "render conn, index.json, data: data", c do
    json = @view.render("index.json", conn: %{}, data: [c[:m1], c[:m2]])
    assert [a1, _a2] = json["data"]
    assert Dict.has_key?(a1, "id")
    assert Dict.has_key?(a1, "attributes")
  end

  test "render conn, index.json-api, articles: models", c do
    json = @view.render("index.json-api", conn: %{}, articles: [c[:m1], c[:m2]])
    assert [a1, _a2] = json["data"]
    assert Dict.has_key?(a1, "id")
    assert Dict.has_key?(a1, "attributes")
  end

  test "render conn, index.json-api, model: model with custom pagination", c do
    json = @view.render("index.json-api", conn: %{}, data: [c[:m1], c[:m2]],
      opts: [page: [first: "/v1/posts/foo"]])
    assert [a1, _a2] = json["data"]
    assert Dict.has_key?(a1, "id")
    assert Dict.has_key?(a1, "attributes")
    assert Dict.has_key?(json, "links")
  end

  test "render conn, index.json-api, model: model with scrivener pagination", c do
    model = %Scrivener.Page{entries: [c[:m1], c[:m2]], page_number: 1}
    conn = %Plug.Conn{query_params: %{}}
    json = @view.render("index.json-api", conn: conn, data: model)
    assert [a1, _a2] = json["data"]
    assert Dict.has_key?(a1, "id")
    assert Dict.has_key?(a1, "attributes")
    assert Dict.has_key?(json, "links")
  end

  test "render conn, show.json-api, data: model", c do
    json = @view.render("show.json-api", conn: %{}, data: c[:m1])
    assert Dict.has_key?(json["data"], "id")
    assert Dict.has_key?(json["data"], "attributes")
  end

  # This should be deprecated in the future
  test "render conn, show.json, data: model", c do
    json = @view.render("show.json", conn: %{}, data: c[:m1])
    assert Dict.has_key?(json["data"], "id")
    assert Dict.has_key?(json["data"], "attributes")
  end

  test "render conn, show.json-api, article: model", c do
    json = @view.render("show.json-api", conn: %{}, article: c[:m1])
    assert Dict.has_key?(json["data"], "id")
    assert Dict.has_key?(json["data"], "attributes")
  end

  test "render conn, 'errors.json-api', data: changeset" do
    errors = Ecto.Changeset.add_error(%Ecto.Changeset{}, :title, "is invalid")
    json = @view.render("errors.json-api", conn: %{}, data: errors)
    assert Dict.has_key?(json, "errors")
    assert [e1] = json["errors"]
    assert e1.source.pointer == "/data/attributes/title"
    assert e1.detail == "Title is invalid"
  end

  # This should be deprecated in the future
  test "render conn, 'errors.json', data: changeset" do
    errors = Ecto.Changeset.add_error(%Ecto.Changeset{}, :title, "is invalid")
    json = @view.render("errors.json", conn: %{}, data: errors)
  end
end
