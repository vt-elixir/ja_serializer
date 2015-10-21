defmodule JaSerializer.Builder.Relationship do
  @moduledoc false

  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.ResourceIdentifier

  defstruct [:name, :links, :data, :meta]

  def build(%{serializer: serializer} = context) do
    Enum.map serializer.__relations, &(build(&1, context))
  end

  defp build({_type, name, _opts} = definition, context) do
    %__MODULE__{name: name}
    |> add_links(definition, context)
    |> add_data(definition, context)
  end

  defp add_links(relation, {_type, _name, opts}, context) do
    case opts[:link] do
      nil ->  relation
      path -> Map.put(relation, :links, [Link.build(context, :related, path)])
    end
  end

  defp add_data(relation, {_t, name, opts}, context) do
    opts
    |> type_from_opts
    |> case do
      nil  -> relation
      type ->
        context = Map.put(context, :resource_serializer, opts[:serializer])
        Map.put(relation, :data, ResourceIdentifier.build(context, type, name))
    end
  end

  defp type_from_opts(opts) do
    case {opts[:type], opts[:serializer]} do
      {nil, nil}        -> nil
      {nil, serializer} -> apply(serializer, :type, [])
      {type, _}         -> type
    end
  end
end
