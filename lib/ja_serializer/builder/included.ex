defmodule JaSerializer.Builder.Included do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject

  def build(%{model: models} = context, primary_resources) when is_list(models) do
    do_build(models, context, [], List.wrap(primary_resources))
  end

  def build(context, primary_resources) do
    context
    |> Map.put(:model, [context.model])
    |> build(primary_resources)
  end

  defp do_build([], _context, included, _known_resources), do: included
  defp do_build([model | models], context, included, known) do
    context = Map.put(context, :model, model)

    new = context
          |> relationships_with_include
          |> Enum.flat_map(&resources_for_relationship(&1, context, included, known))
          |> Enum.uniq(&({&1.id, &1.type}))
          |> reject_known(included, known)

    # Call for next model
    do_build(models, context, (new ++ included), known)
  end

  defp resource_objects_for(models, conn, serializer, fields) do
    ResourceObject.build(%{model: models, conn: conn, serializer: serializer, opts: [fields: fields]})
    |> List.wrap
  end

  # Find relationships that should be included.
  defp relationships_with_include(context) do
    context.serializer.__relations
    |> Enum.filter(fn({_t, rel_name, rel_opts}) ->
      case context[:opts][:include] do
        # if `include` param is not present only return 'default' includes
        nil -> rel_opts[:include] == true

        # otherwise only include requested includes
        includes -> is_list(includes[rel_name])
      end
    end)
  end

  # Find resources for relationship & parent_context
  defp resources_for_relationship({_, name, opts}, context, included, known) do
    context_opts = context[:opts]
    new = apply(context.serializer, name, [context.model, context.conn])
          |> List.wrap
          |> resource_objects_for(context.conn, opts[:serializer], context_opts[:fields])
          |> reject_known(included, known)

    child_context = context
    |> Map.put(:serializer, opts[:serializer])
    |> Map.put(:opts, opts_with_includes_for_relation(context_opts, name))

    new
    |> Enum.map(&(&1.model))
    |> do_build(child_context, (new ++ included), known)
  end

  defp reject_known(resources, included, primary) do
    Enum.reject(resources, &(&1 in included || &1 in primary))
  end

  defp opts_with_includes_for_relation(opts, rel_name) do
    case opts[:include] do
      nil -> opts
      includes -> Keyword.put(opts, :include, includes[rel_name])
    end
  end
end
