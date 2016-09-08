defimpl JaSerializer.Formatter, for: JaSerializer.Builder.TopLevel do
  alias JaSerializer.Formatter.Utils

  def format(struct) do
    %{"jsonapi" =>  %{"version" => "1.0"}}
    |> Map.put("data", JaSerializer.Formatter.format(struct.data))
    |> format_links(struct.links)
    |> Utils.put_if_present("meta", JaSerializer.Formatter.format(struct.meta))
    |> Utils.put_if_present("included", JaSerializer.Formatter.format(struct.included))
  end

  defp format_links(resource, nil), do: resource
  defp format_links(resource, []), do: resource

  defp format_links(resource, links) do
    links = links
            |> JaSerializer.Formatter.format
            |> Enum.reject(&(is_nil(&1)))
            |> Enum.into(%{})
    Map.put(resource, "links", links)
  end
end
