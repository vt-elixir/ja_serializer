defmodule JaSerializer.Builder.TopLevel do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject
  alias JaSerializer.Builder.Included
  alias JaSerializer.Builder.Link

  defstruct [:data, :errors, :included, :meta, {:links, []}, :jsonapi]

  if Code.ensure_loaded?(Scrivener) do
    def build(context = %{data: %Scrivener.Page{} = page, opts: opts}) do
      # Build scrivener pagination links before we lose page object
      links = JaSerializer.Builder.ScrivenerLinks.build(context)
      opts = Dict.update(opts, :page, links, &(Dict.merge(&1, links)))

      # Extract entries from page object
      build(%{context | data: page.entries, opts: opts})
    end
  end

  def build(%{data: records, conn: conn, serializer: serializer} = context) do
    opts = normalize_opts(context[:opts])
    context = context
              |> Map.put(:opts, opts)
              |> Map.put(:data, serializer.preload(records, conn, Keyword.get(opts, :include, [])))

    data = ResourceObject.build(context)
    %__MODULE__{}
    |> Map.put(:data, data)
    |> add_included(context)
    |> add_pagination_links(context)
    |> add_meta(context[:opts][:meta])
  end

  defp add_included(tl, %{opts: opts} = context) do
    case opts[:relationships] do
      false -> tl
      _     -> Map.put(tl, :included, Included.build(context, tl.data))
    end
  end

  defp add_pagination_links(tl, context) do
    links = pagination_links(context.opts[:page], context)
    Map.update(tl, :links, links, &(&1 ++ links))
  end

  defp pagination_links(nil, _), do: []
  defp pagination_links(page, context) do
    page
    |> Dict.take([:self, :first, :next, :prev, :last])
    |> Enum.map(fn({type, url}) -> Link.build(context, type, url) end)
  end

  defp normalize_opts(opts) do
    case opts[:include] do
      nil -> opts
      includes -> Keyword.put(opts, :include, normalize_includes(includes))
    end
  end

  defp normalize_includes(includes) do
    includes
    |> String.split(",")
    |> normalize_relationship_path_list
  end

  defp normalize_relationship_path_list(paths), do:
    normalize_relationship_path_list(paths, [])

  defp normalize_relationship_path_list([], normalized), do: normalized
  defp normalize_relationship_path_list([path | paths], normalized) do
    normalized = path
    |> String.split(".")
    |> normalize_relationship_path
    |> deep_merge_relationship_paths(normalized)

    normalize_relationship_path_list(paths, normalized)
  end

  defp normalize_relationship_path([]), do: []
  defp normalize_relationship_path([rel_name | remaining]) do
    Keyword.put([], String.to_atom(rel_name), normalize_relationship_path(remaining))
  end

  defp deep_merge_relationship_paths(left, right), do: Keyword.merge(left, right, &deep_merge_relationship_paths/3)
  defp deep_merge_relationship_paths(_key, left, right), do: deep_merge_relationship_paths(left, right)

  defp add_meta(tl, nil), do: tl
  defp add_meta(tl, %{} = meta), do: Map.put(tl, :meta, meta)
end
