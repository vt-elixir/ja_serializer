defimpl JaSerializer.Formatter, for: JaSerializer.Builder.ResourceObject do
  alias JaSerializer.Formatter.Utils

  def format(resource) do
    relationships = Utils.array_to_hash(resource.relationships)
    links = Utils.array_to_hash(resource.links)

    json = %{
      "id"         => to_string(resource.id),
      "type"       => resource.type,
      "attributes" => Utils.array_to_hash(resource.attributes),
    }

    json
    |> Utils.put_if_present("relationships", relationships)
    |> Utils.put_if_present("links", links)
    |> Utils.put_if_present("meta", JaSerializer.Formatter.format(resource.meta))
  end
end
