if Code.ensure_loaded?(Scrivener) do
  defmodule JaSerializer.Builder.ScrivenerLinks do

    @moduledoc """
    Builds JSON-API spec pagination links for %Scrivener.Page{}.
    """

    @first_page 1

    @spec build(map) :: map
    def build(context = %{model: %Scrivener.Page{}}) do
      {[], context}
      |> current_page
      |> previous_pages
      |> next_pages
      |> create_urls
    end

    defp current_page({list, %{model: page} = context}) do
      {list ++ [self: page.page_number], context}
    end

    defp previous_pages({list, %{model: page} = context}) do
      if page.page_number == 1 do
        {list, context}
      else
        prev = page.page_number - @first_page
        {list ++ [first: @first_page, prev: prev], context}
      end
    end

    defp next_pages({list, %{model: page} = context}) do
      if page.page_number == page.total_pages do
        {list, context}
      else
        next = page.page_number + @first_page
        {list ++ [last: page.total_pages, next: next], context}
      end
    end

    defp create_urls({list, context}) do
      list
      |> Enum.map(&(page_url(&1, context)))
      |> Enum.into(%{})
    end

    defp page_url({key, val}, %{opts: opts, conn: conn, model: page}) do
      base = opts[:page][:base_url] || conn.request_path
      page_params = %{"page" => %{"page" => val, "page_size" => page.page_size}}
      params = conn.query_params
                |> Dict.merge(page_params)
                |> Plug.Conn.Query.encode
      {key, "#{base}?#{params}"}
    end
  end
end
