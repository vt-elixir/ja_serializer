if Code.ensure_loaded?(Scrivener) do
  defmodule JaSerializer.Builder.ScrivenerLinks do
    @moduledoc """
    Builds JSON-API spec pagination links for %Scrivener.Page{}.
    """

    @spec build(map) :: map
    def build(%{data: data = %Scrivener.Page{}, opts: opts, conn: conn}) do
      data = %{
        number: data.page_number,
        size: data.page_size,
        total: data.total_pages,
        base_url: opts[:base_url]
      }

      JaSerializer.Builder.PaginationLinks.build(data, conn)
    end
  end
end
