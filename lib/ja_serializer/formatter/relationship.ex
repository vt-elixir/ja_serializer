defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Relationship do
  alias JaSerializer.Formatter.Utils

  def format(rel) do
    json = %{}
    |> Utils.put_if_present(:data, JaSerializer.Formatter.format(rel.data))
    |> Utils.put_if_present(:links, Utils.array_to_hash(rel.links))
    {Utils.dasherize(rel.name), json}
  end
end
