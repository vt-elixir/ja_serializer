defmodule JaSerializer.Builder.PaginationLinks do
  import JaSerializer.Formatter.Utils, only: [format_key: 1]

  @page_number_origin Application.get_env(:ja_serializer, :page_number_origin, 1)

  @moduledoc """
  Builds JSON-API spec pagination links.

  Pass in a map with the necessary data:

      JaSerializer.Builder.PaginationLinks.build(%{
          number: 1,
          size: 20,
          total: 5,
          base_url: "https://example.com"
        },
        Plug.Conn%{}
      )

  Would produce a list of links such as:

      [
        self: "https://example.com/posts?page[number]=2&page[size]=10",
        next: "https://example.com/posts?page[number]=3&page[size]=10",
        first: "https://example.com/posts?page[number]=1&page[size]=10",
        last: "https://example.com/posts?page[number]=20&page[size]=10"
      ]

  The param names can be customized on your application's config:

      config :ja_serializer,
        page_key: "page",
        page_base_url: "https://example.com/posts"
        page_number_key: "offset",
        page_size_key: "limit",
        page_number_origin: 0,

  The defaults are:

  * `page_key` : `"page"`
  * `page_base_url`: `nil`
  * `page_number_key`: `"number"`
  * `page_size_key` : `"size"`
  * `page_number_origin`: `1`

  Please note that if the value for `page_number_origin` is changed JaSerializer will have to be recompiled:

      $ mix deps.clean ja_serializer
      $ mix deps.get ja_serializer
  """

  # @spec build(data, conn) :: map, map
  def build(data, conn) do
    base = base_url(conn, data[:base_url])

    data
    |> links()
    |> Enum.into(%{}, fn {link, number} ->
      {link, page_url(number, base, data.size, conn.query_params)}
    end)
  end

  defp links(%{number: @page_number_origin, total: 1}),
    do: [self: @page_number_origin]
  defp links(%{number: @page_number_origin, total: 0}),
    do: [self: @page_number_origin]
  defp links(%{number: @page_number_origin, total: t}),
    do: [self: @page_number_origin, next: 2, last: t]
  defp links(%{number: total, total: total}),
    do: [self: total, first: @page_number_origin, prev: total - 1]
  defp links(%{number: number, total: total}),
    do: [self: number, first: @page_number_origin, prev: number - 1, next: number + 1, last: total]

  defp page_url(number, base, size, orginal_params) do
    params =
      orginal_params
      |> Map.merge(page_params(number, size))
      |> Plug.Conn.Query.encode

    "#{base}?#{params}"
  end

  defp page_params(number, size) do
    case page_key() do
      nil -> %{page_number_key() => number, page_size_key() => size}
      key -> %{key => %{page_number_key() => number, page_size_key() => size}}
    end
  end

  defp page_key do
    Application.get_env(:ja_serializer, :page_key, format_key("page"))
  end

  defp page_number_key do
    Application.get_env(:ja_serializer, :page_number_key, format_key("number"))
  end

  defp page_size_key do
    Application.get_env(:ja_serializer, :page_size_key, format_key("size"))
  end

  defp base_url(conn, nil) do
    Application.get_env(:ja_serializer, :page_base_url, "") <> conn.request_path
  end
  defp base_url(_conn, url), do: url
end
