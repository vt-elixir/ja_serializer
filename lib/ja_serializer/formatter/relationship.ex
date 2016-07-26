defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Relationship do
  alias JaSerializer.Formatter.Utils

  def format(rel) do
    json = %{}
    |> Utils.add_data_if_present(JaSerializer.Formatter.format(rel.data))
    |> Utils.put_if_present("links", Utils.array_to_hash(rel.links))
    {Utils.format_key(rel.name), json}
  end
end
