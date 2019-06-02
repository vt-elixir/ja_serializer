defmodule JaSerializer.Builder.TopLevel do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject
  alias JaSerializer.Builder.Included
  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.Utils

  defstruct [:data, :errors, :included, :meta, {:links, []}, :jsonapi]

  if Code.ensure_loaded?(Scrivener) do
    def build(context = %{data: %Scrivener.Page{} = page, opts: opts}) do
      opts = Enum.into(opts, %{})
      # Build scrivener pagination links before we lose page object
      links = JaSerializer.Builder.ScrivenerLinks.build(context)
      opts = Map.update(opts, :page, links, &Map.merge(links, &1))

      # Extract entries from page object
      build(%{context | data: page.entries, opts: opts})
    end
  end

  def build(%{data: records, conn: conn, serializer: serializer} = context) do
    opts = normalize_opts(context[:opts])

    context =
      context
      |> Map.put(:opts, opts)
      |> Map.put(
        :data,
        serializer.preload(records, conn, Map.get(opts, :include, []))
      )

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
      _ -> Map.put(tl, :included, Included.build(context, tl.data))
    end
  end

  defp add_pagination_links(tl, context) do
    links = pagination_links(context.opts[:page], context)
    Map.update(tl, :links, links, &(&1 ++ links))
  end

  defp pagination_links(nil, _), do: []

  defp pagination_links(page, context) do
    page
    |> Enum.into(%{})
    |> Map.take([:self, :first, :next, :prev, :last])
    |> Enum.map(fn {type, url} -> Link.build(context, type, url) end)
  end

  defp normalize_opts(opts) do
    opts = Enum.into(opts, %{})

    case opts[:include] do
      nil -> opts
      includes -> Map.put(opts, :include, Utils.normalize_includes(includes))
    end
  end

  defp add_meta(tl, nil), do: tl
  defp add_meta(tl, %{} = meta), do: Map.put(tl, :meta, meta)
end
