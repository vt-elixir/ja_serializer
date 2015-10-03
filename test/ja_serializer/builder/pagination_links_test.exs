defmodule JaSerializer.Builder.PaginationLinksTest do
  use ExUnit.Case

  defmodule Page do
    defstruct [page_number: 3, total_pages: 5, page_size: 10]
  end
  alias JaSerializer.Builder.PaginationLinks

  test "when current page is first, do not include first, prev links" do
    links = PaginationLinks.build("/api/posts", %Page{page_number: 1})

    assert Enum.sort([:self, :last, :next]) == Dict.keys(links) |> Enum.sort
    assert [
      "/api/posts/page=1&page_size=10",
      "/api/posts/page=2&page_size=10",
      "/api/posts/page=5&page_size=10"
    ] == Dict.values(links) |> Enum.sort
  end

  test "when current page is in the middle, includes all links" do
    links = PaginationLinks.build("/api/posts", %Page{})

    assert Enum.sort([:self, :first, :prev, :last, :next]) == Dict.keys(links) |> Enum.sort
    assert [
      "/api/posts/page=1&page_size=10",
      "/api/posts/page=2&page_size=10",
      "/api/posts/page=3&page_size=10",
      "/api/posts/page=4&page_size=10",
      "/api/posts/page=5&page_size=10"
    ] == Dict.values(links) |> Enum.sort
  end

  test "when current page is the last, do not include last, next links" do
    links = PaginationLinks.build("/api/posts", %Page{page_number: 5})

    assert Enum.sort([:self, :first, :prev]) == Dict.keys(links) |> Enum.sort
    assert [
      "/api/posts/page=1&page_size=10",
      "/api/posts/page=4&page_size=10",
      "/api/posts/page=5&page_size=10"
    ] == Dict.values(links) |> Enum.sort
  end
end
