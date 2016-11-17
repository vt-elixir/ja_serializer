if Code.ensure_loaded?(Scrivener) do
  defmodule JaSerializer.Builder.ScrivenerLinks do

    import JaSerializer.Formatter.Utils, only: [format_key: 1]

    @moduledoc """
    Builds JSON-API spec pagination links for %Scrivener.Page{}.
    """

    @spec build(map) :: map
    def build(%{data: data = %Scrivener.Page{}, opts: opts, conn: conn}) do
      base = opts[:page][:base_url] || conn.request_path

      data
      |> pages
      |> Enum.reduce(%{}, fn {key, num}, acc ->
        Map.put(acc, key, page_url(num, base, data.page_size, conn.query_params))
      end)
    end

    defp pages(%{page_number: 1, total_pages: 1}),
      do: [self: 1]
    defp pages(%{page_number: 1, total_pages: 0}),
      do: [self: 1]
    defp pages(%{page_number: 1, total_pages: t}),
      do: [self: 1, next: 2, last: t]
    defp pages(%{page_number: t, total_pages: t}),
      do: [self: t, first: 1, prev: t - 1]
    defp pages(%{page_number: n, total_pages: t}),
      do: [self: n, first: 1, prev: n - 1, next: n + 1, last: t]

    defp page_url(num, base, page_size, orginal_params) do
      params =
        orginal_params
        |> Map.merge(%{page_key => %{page_number_key => num, page_size_key => page_size}})
        |> Plug.Conn.Query.encode

      "#{base}?#{params}"
    end

    defp page_key do
      Application.get_env(:ja_serializer, :page_key, format_key("page"))
    end

    defp page_number_key do
      Application.get_env(:ja_serializer, :page_number_key, format_key("page"))
    end

    defp page_size_key do
      Application.get_env(:ja_serializer, :page_size_key, format_key("page_size"))
    end
  end
end
