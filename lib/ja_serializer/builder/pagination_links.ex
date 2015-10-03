defmodule JaSerializer.Builder.PaginationLinks do

  @moduledoc """
  To build pagination links part of the data attr in a jsonapi spec.

    iex> page = %Page{page_number: 3, total_pages: 5, page_size: 10}
    iex> PaginationLinks.build("/api/posts", page)
        [self: "/api/posts/page=3&page_size=10",
        first: "/api/posts/page=1&page_size=10",
        prev: "/api/posts/page=2&page_size=10",
        last: "/api/posts/page=5&page_size=10",
        next: "/api/posts/page=4&page_size=10"]
    iex2>
  """

  @first_page 1

  @spec build(String.t, map) :: [key: String.t]
  def build(url, page) do
    {[], page}
    |> current_page
    |> previous_pages
    |> next_pages
    |> create_urls(url)
  end

  defp current_page({list, page}) do
    {list ++ [self: page.page_number], page}
  end

  defp previous_pages({list, page}) do
    if page.page_number == 1 do
      {list, page}
    else
      prev = page.page_number - @first_page
      {list ++ [first: @first_page, prev: prev], page}
    end
  end

  defp next_pages({list, page}) do
    if page.page_number == page.total_pages do
      {list, page}
    else
      next = page.page_number + @first_page
      {list ++ [last: page.total_pages, next: next], page}
    end
  end

  defp create_urls({list, page}, url) do
    Enum.map(list, fn {key, val} ->
      params = %{page: val, page_size: page.page_size} |> URI.encode_query
      final_url = "#{url}/#{params}"
      {key, final_url}
    end)
  end
end
