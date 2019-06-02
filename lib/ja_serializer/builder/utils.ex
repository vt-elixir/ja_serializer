defmodule JaSerializer.Builder.Utils do
  @moduledoc """
  Utilities to work with building serialized data
  """

  def normalize_includes(nil), do: []
  def normalize_includes(""), do: []

  def normalize_includes(includes) do
    includes
    |> String.split(",")
    |> normalize_relationship_path_list
  end

  defp normalize_relationship_path_list(paths),
    do: normalize_relationship_path_list(paths, [])

  defp normalize_relationship_path_list([], normalized), do: normalized

  defp normalize_relationship_path_list([path | paths], normalized) do
    normalized =
      path
      |> String.split(".")
      |> Enum.map(&JaSerializer.ParamParser.Utils.format_key/1)
      |> normalize_relationship_path
      |> deep_merge_relationship_paths(normalized)

    normalize_relationship_path_list(paths, normalized)
  end

  defp normalize_relationship_path([]), do: []

  defp normalize_relationship_path([rel_name | remaining]) do
    Keyword.put(
      [],
      String.to_atom(rel_name),
      normalize_relationship_path(remaining)
    )
  end

  defp deep_merge_relationship_paths(left, right),
    do: Keyword.merge(left, right, &deep_merge_relationship_paths/3)

  defp deep_merge_relationship_paths(_key, left, right),
    do: deep_merge_relationship_paths(left, right)
end
