defimpl JaSerializer.Formatter, for: JaSerializer.Builder.ResourceObject do
  alias JaSerializer.Formatter.Utils

  def format(resource) do
    %{
      id:            to_string(resource.id),
      type:          resource.type,
      attributes:    Utils.array_to_hash(resource.attributes),
      relationships: Utils.array_to_hash(resource.relationships)
    }
  end
end
