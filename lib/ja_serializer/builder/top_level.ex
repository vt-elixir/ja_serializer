defmodule JaSerializer.Builder.TopLevel do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject
  alias JaSerializer.Builder.Included
  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.PaginationLinks

  defstruct [:data, :errors, :included, :meta, :links, :jsonapi]

  def build(context) do
    data = ResourceObject.build(context)
    %__MODULE__{}
    |> Map.put(:data, data)
    |> Map.put(:included, Included.build(context, data))
    |> add_meta(context)
    |> add_links(context)
  end

  def add_links(tl, %{opts: %{page: _}} = context) do
    data = tl.data
    if is_list(data) do
      links = data
              |> hd
              |> find_index_url
              |> map_links(data, context)
      Map.put(tl, :links, links)
    else
      tl
    end
  end

  def add_links(tl, _context), do: tl

  #TODO: Add meta
  def add_meta(tl, _context), do: tl

  defp find_index_url(data) do
    root_link = data.links |> hd
    String.replace(root_link.href, ~r{\/\d+/?$}, "")
  end

  defp map_links(index_url, list, context) do
    index_url
    |> PaginationLinks.build(context.opts.page)
    |> Enum.map(fn({type, url}) -> Link.build(context, type, url) end)
  end
end
