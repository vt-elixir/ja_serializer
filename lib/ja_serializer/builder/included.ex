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
  defp do_build([model | models], context, included, known_resources) do
    context = Map.put(context, :model, model)

    # Find all relationships to include
    rels = included_relationships(context)

    # return all direct and decendant includes.
    new_included = Enum.flat_map rels, fn({_, name, opts}) ->
      # find related models
      related_models = apply(context.serializer, name, [context.model, context.conn]) |> List.wrap

      # generate resource objects
      related_resources = resource_objects_for(related_models, context.conn, opts[:include])

      # If already included, remove.
      de_duped = Enum.reject(related_resources, &(&1 in included || &1 in known_resources))

      # find decendant included.
      do_build(related_models, context, de_duped, (known_resources ++ included))
      |> Enum.uniq(&({&1.id, &1.type}))
    end

    # Call for next model
    do_build(models, context, (new_included ++ included), known_resources)
    |> Enum.uniq(&({&1.id, &1.type}))
  end

  defp resource_objects_for(models, conn, serializer) do
    ResourceObject.build(%{model: models, conn: conn, serializer: serializer})
    |> List.wrap
  end

  defp included_relationships(context) do
    context.serializer.__relations
    |> Enum.filter(fn({_t, _n, opts}) -> opts[:include] != nil end)
  end
end
