defmodule JaSerializer.Builder.Link do
  @moduledoc false

  @param_fetcher_regex ~r/:\w+/

  defstruct href: nil, meta: nil, type: :related

  def build(context) do
    context.data
    |> context.serializer.links(context.conn)
    |> Enum.map(fn({type, path}) -> build(context, type, path) end)
  end

  def build(_context, _type, nil), do: nil

  def build(context, type, path) when is_binary(path) do
    %__MODULE__{
      href: path_for_context(context, path),
      type: type
    }
  end

  def build(context, type, path) when is_atom(path) do
    %__MODULE__{
      href: apply(context.serializer, path, [context.data, context.conn]),
      type: type
    }
  end

  defp path_for_context(context, path) do
    uri = URI.parse(path)
    path = uri
    |> Map.put(:path, replaced_path_for_context(context, uri.path))
    |> Map.put(:query, replaced_path_for_context(context, uri.query))
    |> URI.to_string

    # Remove trailing question mark if there is no query string.
    # A query string itself can contain a trailing question mark so we only
    # do this if URI did not parse out a query.
    if nil == uri.query do
      Regex.replace ~r/\?$/, path, ""
    else
      path
    end
  end

  defp replaced_path_for_context(_context, nil), do: ""

  defp replaced_path_for_context(context, path) do
    @param_fetcher_regex
    |> Regex.replace(path, &frag_for_context(&1, context))
  end

  defp frag_for_context(":" <> frag, %{serializer: serializer} = context) do
    "#{apply(serializer, String.to_atom(frag), [context.data, context.conn])}"
  end
end
