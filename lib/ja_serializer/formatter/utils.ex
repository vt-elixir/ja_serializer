defmodule JaSerializer.Formatter.Utils do
  @moduledoc false

  @doc false
  def put_if_present(dict, _key, nil), do: dict
  def put_if_present(dict, _key, []),  do: dict
  def put_if_present(dict, _key, ""),  do: dict
  def put_if_present(dict, _key, %{} = map) when map_size(map) == 0, do: dict
  def put_if_present(dict, key, val), do: Dict.put(dict, key, val)

  @doc false
  def add_data_if_present(dict, :empty_relationship), do: Dict.put(dict, :data, nil)
  def add_data_if_present(dict, [:empty_relationship]), do: Dict.put(dict, :data, [])
  def add_data_if_present(dict, val), do: put_if_present(dict, :data, val)

  @doc false
  def array_to_hash(nil),   do: nil
  def array_to_hash([nil]), do: nil
  def array_to_hash(structs) do
    structs
    |> Enum.map(&JaSerializer.Formatter.format/1)
    |> Enum.into(%{})
  end

  @key_formatter Application.get_env(:ja_serializer, :key_format, :dasherized)
  @dasherize ~r/_/

  @doc false
  def format_key(k) when is_atom(k), do: k |> Atom.to_string |> format_key
  def format_key(key), do: do_format_key(key, @key_formatter)


  @doc false
  def do_format_key(key, :underscored), do: key
  def do_format_key(key, :dasherized), do: String.replace(key, @dasherize, "-")
  def do_format_key(key, {:custom, module, fun}), do: apply(module, fun, [key])
end
