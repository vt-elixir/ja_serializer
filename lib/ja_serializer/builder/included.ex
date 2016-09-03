defmodule JaSerializer.Builder.Included do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject

  defp resource_key(resource) do
    {resource.id, resource.type}
  end

  def build(%{data: data} = context, primary_resources) when is_list(data) do
    known = primary_resources
            |> List.wrap
            |> Enum.map(&resource_key/1)
            |> Enum.into(HashSet.new)

    data
    |> do_build(context, %{}, known)
    |> Map.values
  end

  def build(context, primary_resources) do
    context
    |> Map.put(:data, [context.data])
    |> build(primary_resources)
  end

  defp do_build([], _context, included, _known_resources), do: included
  defp do_build([struct | structs], context, included, known) do
    context  = Map.put(context, :data, struct)
    included = context
                |> relationships_with_include
                |> Enum.reduce(included, fn rel_definition, included ->
                  resources_for_relationship(rel_definition, context, included, known)
                end)
    do_build(structs, context, included, known)
  end

  defp resource_objects_for(structs, conn, serializer, opts) do
    %{data: structs, conn: conn, serializer: serializer, opts: opts}
    |> ResourceObject.build
    |> List.wrap
  end

  # Find relationships that should be included.
  defp relationships_with_include(context) do
    context.data
    |> context.serializer.relationships(context.conn)
    |> Enum.filter(fn({rel_name, rel_definition}) ->
      case context[:opts][:include] do
        # if `include` param is not present only return 'default' includes
        nil -> rel_definition.include == true

        # otherwise only include requested includes
        includes -> is_list(includes[rel_name])
      end
    end)
  end

  # Find resources for relationship & parent_context
  defp resources_for_relationship({name, definition}, context, included, known) do
    context_opts     = context[:opts]
    child_opts       = context_opts
                       |> opts_with_includes_for_relation(name)
    {cont, included} = context
                       |> get_data(definition)
                       |> List.wrap
                       |> resource_objects_for(context.conn, definition.serializer, child_opts)
                       |> Enum.reduce({[], included}, fn item, {cont, included} ->
                         key = resource_key(item)
                         if HashSet.member?(known, key) or Map.has_key?(included, key) do
                           {cont, included}
                         else
                           {[item.data | cont], Map.put(included, key, item)}
                         end
                       end)

    child_context = context
    |> Map.put(:serializer, definition.serializer)
    |> Map.put(:opts, child_opts)

    do_build(cont, child_context, included, known)
  end

  defp get_data(_, %{data: nil}), do: nil
  defp get_data(context, %{data: data}) when is_atom(data) do
    context.serializer
    |> apply(data, [context.data, context.conn])
  end
  defp get_data(_, %{data: data}), do: data

  defp opts_with_includes_for_relation(opts, rel_name) do
    case opts[:include] do
      nil -> opts
      includes -> Keyword.put(opts, :include, includes[rel_name])
    end
  end
end
