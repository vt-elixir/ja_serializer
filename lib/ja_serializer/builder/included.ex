defmodule JaSerializer.Builder.Included do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject

  defp resource_key(resource) do
    {resource.id, resource.type}
  end

  def build(%{data: data} = context, primary_resources) when is_list(data) do
    primary_ro_list = List.wrap(primary_resources)

    known =
      primary_ro_list
      |> Enum.map(&resource_key/1)
      |> Enum.into(MapSet.new())

    # Build a cache mapping each data struct to its pre-computed relationship
    # definitions from the already-built ResourceObjects. This avoids calling
    # serializer.relationships/2 again for the top-level data.
    rel_def_cache = build_rel_def_cache(primary_ro_list)
    context = Map.put(context, :rel_def_cache, rel_def_cache)

    data
    |> do_build(context, %{}, known)
    |> Map.values()
  end

  def build(context, primary_resources) do
    context
    |> Map.put(:data, [context.data])
    |> build(primary_resources)
  end

  defp do_build([], _context, included, _known_resources), do: included

  defp do_build([struct | structs], context, included, known) do
    # Look up pre-computed relationship definitions for this struct.
    # Falls back to nil when no cache entry exists, which causes
    # relationships_with_include to compute them on demand.
    rel_defs = context[:rel_def_cache][struct]

    context =
      context
      |> Map.put(:data, struct)
      |> Map.put(:relationship_definitions, rel_defs)

    included =
      context
      |> relationships_with_include
      |> Enum.reduce(included, fn rel_definition, included ->
        resources_for_relationship(rel_definition, context, included, known)
      end)

    do_build(structs, context, included, known)
  end

  defp resource_objects_for(structs, conn, serializer, opts) do
    structs = Enum.filter(structs, &is_map/1)

    %{data: structs, conn: conn, serializer: serializer, opts: opts}
    |> ResourceObject.build()
    |> List.wrap()
  end

  # Find relationships that should be included.
  defp relationships_with_include(context) do
    rel_defs =
      context[:relationship_definitions] ||
        context.serializer.relationships(context.data, context.conn)

    Enum.filter(rel_defs, fn {rel_name, rel_definition} ->
      case context[:opts][:include] do
        # if `include` param is not present only return 'default' includes
        nil ->
          rel_definition.include == true

        # otherwise only include requested includes
        includes ->
          is_list(includes[rel_name])
      end
    end)
  end

  # Find resources for relationship & parent_context
  defp resources_for_relationship({name, definition}, context, included, known) do
    context_opts = context[:opts]

    child_opts =
      context_opts
      |> opts_with_includes_for_relation(name)

    resource_objects =
      context
      |> get_data(definition)
      |> List.wrap()
      |> resource_objects_for(context.conn, definition.serializer, child_opts)

    # Build a cache from the child ResourceObjects so the recursive do_build
    # call doesn't need to recalculate serializer.relationships/2 either.
    child_rel_def_cache = build_rel_def_cache(resource_objects)

    {cont, included} =
      Enum.reduce(resource_objects, {[], included}, fn item, {cont, included} ->
        key = resource_key(item)

        if MapSet.member?(known, key) or Map.has_key?(included, key) do
          {cont, included}
        else
          {[item.data | cont], Map.put(included, key, item)}
        end
      end)

    child_context =
      context
      |> Map.put(:serializer, definition.serializer)
      |> Map.put(:opts, child_opts)
      |> Map.put(:rel_def_cache, child_rel_def_cache)

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
      includes -> Map.put(opts, :include, includes[rel_name])
    end
  end

  # Build a map from raw data struct -> relationship_definitions
  # using already-built ResourceObjects to avoid recalculating.
  defp build_rel_def_cache(resource_objects) do
    resource_objects
    |> List.wrap()
    |> Enum.reduce(%{}, fn ro, cache ->
      if ro.relationship_definitions do
        Map.put(cache, ro.data, ro.relationship_definitions)
      else
        cache
      end
    end)
  end
end
