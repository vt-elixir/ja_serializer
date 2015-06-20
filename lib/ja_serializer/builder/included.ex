defmodule JaSerializer.Builder.Included do
  alias JaSerializer.Builder.ResourceObject

  #TODO: Handle more then one level of includes
  def build(%{model: models} = context) when is_list(models) do
    Enum.flat_map(models, fn(model) ->
      context = Map.put(context, :model, model)
      context.serializer.__relations
      |> Enum.filter(fn({_t, _n, opts}) -> opts[:include] != nil end)
      |> Enum.flat_map(&resource_for(&1, context))
    end) |> Enum.uniq(&({&1.id, &1.type}))
  end

  def build(context) do
    context
    |> Map.put(:model, [context.model])
    |> build
  end

  defp resource_for({_t, name, opts}, context) do
    models = apply(context.serializer, name, [context.model, context.conn])
    ResourceObject.build(%{
      model: models,
      conn: context.conn,
      serializer: opts[:include]
    }) |> case do
      many when is_list(many) -> many
      one -> [one]
    end
  end
end
