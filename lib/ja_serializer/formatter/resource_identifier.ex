defimpl JaSerializer.Formatter, for: JaSerializer.Builder.ResourceIdentifier do
  def format(resource) do
    required_attributes = %{
      "id"   => to_string(resource.id),
      "type" => resource.type
    }

    add_meta(required_attributes, resource)
  end

  defp add_meta(resource, %{meta: nil}), do: resource
  defp add_meta(resource, %{meta: meta}), do: Map.put(resource, "meta", meta)
end
