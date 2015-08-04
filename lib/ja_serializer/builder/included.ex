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

  defp resource_objects_for(models, conn, serializer) do
    ResourceObject.build(%{model: models, conn: conn, serializer: serializer})
    |> List.wrap
  end

  # Find relationships that should be included.
  defp relationships_with_include(context) do
    context.serializer.__relations
    |> Enum.filter(fn({_t, _n, opts}) -> opts[:include] != nil end)
  end

  # Find resources for relationship & parent_context
  defp resources_for_relationship({_, name, opts}, context, included, known) do
    new = apply(context.serializer, name, [context.model, context.conn])
          |> List.wrap
          |> resource_objects_for(context.conn, opts[:include])
          |> reject_known(included, known)

    child_context = Map.put(context, :serializer, opts[:include])

    new
    |> Enum.map(&(&1.model))
    |> do_build(child_context, (new ++ included), known)
  end

  defp reject_known(resources, included, primary) do
    Enum.reject(resources, &(&1 in included || &1 in primary))
  end
end
