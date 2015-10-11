defmodule JaSerializer.Builder.TopLevel do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject
  alias JaSerializer.Builder.Included
  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.PaginationLinks

  defstruct [:data, :errors, :included, :meta, {:links, []}, :jsonapi]

  if Code.ensure_loaded?(Scrivener) do
    def build(context = %{model: %Scrivener.Page{} = page, opts: opts}) do
      # Build scrivener pagination links before we lose page object
      links = PaginationLinks.build(context)
      opts = Dict.update(opts, :page, links, &(Dict.merge(&1, links)))

      # Extract entries from page object
      %{context | model: page.entries, opts: opts}
      |> build
    end
  end

  def build(context) do
    data = ResourceObject.build(context)
    %__MODULE__{}
    |> Map.put(:data, data)
    |> Map.put(:included, Included.build(context, data))
    |> add_pagination_links(context)
    |> add_meta(context)
  end

  defp add_pagination_links(tl, context) do
    links = pagination_links(context.opts[:page], context)
    Map.update(tl, :links, links, &(&1++links))
  end

  defp pagination_links(nil, _), do: []
  defp pagination_links(page, context) do
    page
    |> Dict.take([:self, :first, :next, :prev, :last])
    |> Enum.map(fn({type, url}) -> Link.build(context, type, url) end)
  end

  #TODO: Add meta
  def add_meta(tl, _context), do: tl
end
