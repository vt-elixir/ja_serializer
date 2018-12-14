defmodule Builder.ScrivenerLinksBench do
  use Benchfella

  @conn %Plug.Conn{request_path: "/widgets", query_params: %{"oh" => "my"}}

  bench "only one page", data: data(1, 1) do
    JaSerializer.Builder.ScrivenerLinks.build(data)
  end

  bench "page one of two pages", data: data(1, 2) do
    JaSerializer.Builder.ScrivenerLinks.build(data)
  end

  bench "page two of three pages", data: data(2, 3) do
    JaSerializer.Builder.ScrivenerLinks.build(data)
  end

  bench "page two of two pages", data: data(2, 2) do
    JaSerializer.Builder.ScrivenerLinks.build(data)
  end

  bench "page one of three pages", data: data(1, 3) do
    JaSerializer.Builder.ScrivenerLinks.build(data)
  end

  bench "page three of three pages", data: data(3, 3) do
    JaSerializer.Builder.ScrivenerLinks.build(data)
  end

  defp data(page, total) do
    page = %Scrivener.Page{page_number: page, total_pages: total}
    %{opts: [], conn: @conn, data: page}
  end
end
