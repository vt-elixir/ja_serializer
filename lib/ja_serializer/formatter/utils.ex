defmodule JaSerializer.Formatter.Utils do
  @moduledoc false

  @doc false
  def put_if_present(dict, _key, nil), do: dict
  def put_if_present(dict, _key, []),  do: dict
  def put_if_present(dict, _key, ""),  do: dict
  def put_if_present(dict, _key, %{} = map) when map_size(map) == 0, do: dict
  def put_if_present(dict, key, val), do: Dict.put(dict, key, val)

  @doc false
  def array_to_hash(nil),   do: nil
  def array_to_hash([nil]), do: nil
  def array_to_hash(structs) do
    Enum.reduce structs, %{}, fn(struct, results) ->
      {key, val} = JaSerializer.Formatter.format(struct)
      Map.put(results, key, val)
    end
  end

  def format_key(k) when is_atom(k), do: k |> Atom.to_string |> format_key
  def format_key(key) do
    case Application.get_env(:ja_serializer, :key_format, :dasherized) do
      :dasherized -> dasherize(key)
      :underscored -> underscore(key)
      {:custom, module, fun} -> apply(module, fun, [key])
    end
  end

  defp dasherize(key), do: String.replace(key, ~r/_/, "-")
  defp underscore(key), do: key

end
