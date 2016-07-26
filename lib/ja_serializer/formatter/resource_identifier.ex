defimpl JaSerializer.Formatter, for: JaSerializer.Builder.ResourceIdentifier do
  def format(resource) do
    %{
      "id"   => to_string(resource.id),
      "type" => resource.type
    }
  end
end
