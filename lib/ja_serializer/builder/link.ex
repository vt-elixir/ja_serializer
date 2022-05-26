defmodule JaSerializer.Builder.Link do
  @moduledoc false

  @param_fetcher_regex ~r/:\w+/

  defstruct href: nil, meta: nil, type: :related

  def build(context) do
    context.data
    |> context.serializer.links(context.conn)
    |> Enum.map(fn {type, path} -> build(context, type, path) end)
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
    path = Map.put(uri, :path, replaced_path_for_context(context, uri.path))

    if valid_fragments?(context, uri.path) do
      if uri.query do
        Map.put(path, :query, replaced_path_for_context(context, uri.query))
      else
        path
      end
      |> URI.to_string()
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

  defp valid_fragments?(_context, nil), do: true

  defp valid_fragments?(%{serializer: serializer} = context, path) do
    fragments = Regex.scan(@param_fetcher_regex, path)

    Enum.all?(fragments, fn [":" <> frag] ->
      frag_value =
        apply(serializer, String.to_atom(frag), [context.data, context.conn])

      !is_nil(frag_value)
    end)
  end
end
