defmodule JaSerializer.Formatter.Utils do
  @moduledoc false

  @doc false
  def put_if_present(dict, _key, nil), do: dict
  def put_if_present(dict, _key, []),  do: dict
  def put_if_present(dict, _key, ""),  do: dict
  def put_if_present(dict, _key, %{} = map) when map_size(map) == 0, do: dict
  def put_if_present(dict, key, val), do: Dict.put(dict, key, val)

  @doc false
  def add_data_if_present(dict, :empty_relationship), do: Dict.put(dict, "data", nil)
  def add_data_if_present(dict, [:empty_relationship]), do: Dict.put(dict, "data", [])
  def add_data_if_present(dict, val), do: put_if_present(dict, "data", val)

  @doc false
  def array_to_hash(nil),   do: nil
  def array_to_hash([nil]), do: nil
  def array_to_hash(structs) do
    structs
    |> Enum.map(&JaSerializer.Formatter.format/1)
    |> Enum.into(%{})
  end

  @key_formatter Application.get_env(:ja_serializer, :key_format, :dasherized)

  @doc false
  def deep_format_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, &deep_format_key_value/2)
  end
  def deep_format_keys(other), do: other

  defp deep_format_key_value({key, value}, accumulator) when is_map(value) do
    Map.put(accumulator, format_key(key), deep_format_keys(value))
  end
  defp deep_format_key_value({key, value}, accumulator) do
    Map.put(accumulator, format_key(key), value)
  end

  @doc false
  def format_key(k) when is_atom(k), do: k |> Atom.to_string |> format_key
  def format_key(key), do: do_format_key(key, @key_formatter)

  @doc false
  def do_format_key(key, :underscored), do: key
  def do_format_key(key, :dasherized),  do: String.replace(key, "_", "-")
  def do_format_key(key, {:custom, module, fun}), do: apply(module, fun, [key])

  @doc false
  def format_type(string), do: do_format_type(string, @key_formatter)

  @doc false
  def do_format_type(string, :dasherized), do: dasherize(string)
  def do_format_type(string, :underscored), do: underscore(string)
  def do_format_type(string, {:custom, module, fun}), do: apply(module, fun, [string])

  @doc false
  def humanize(atom) when is_atom(atom),
    do: humanize(Atom.to_string(atom))
  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end

    bin |> String.replace("_", " ") |> String.capitalize
  end

  @doc false
  def dasherize(""), do: ""

  def dasherize(<<h, t :: binary>>) do
    <<to_lower_char(h)>> <> do_dasherize(t, h)
  end

  defp do_dasherize(<<h, t, rest :: binary>>, _) when h in ?A..?Z and not (t in ?A..?Z or t == ?.) do
    <<?-, to_lower_char(h), t>> <> do_dasherize(rest, t)
  end

  defp do_dasherize(<<h, t :: binary>>, prev) when h in ?A..?Z and not prev in ?A..?Z do
    <<?-, to_lower_char(h)>> <> do_dasherize(t, h)
  end

  defp do_dasherize(<<?., t :: binary>>, _) do
    <<?/>> <> dasherize(t)
  end

  defp do_dasherize(<<?_, t :: binary>>, _) do
    <<?->> <> dasherize(t)
  end

  defp do_dasherize(<<h, t :: binary>>, _) do
    <<to_lower_char(h)>> <> do_dasherize(t, h)
  end

  defp do_dasherize(<<>>, _) do
    <<>>
  end

  @doc false
  def underscore(""), do: ""

  def underscore(<<h, t :: binary>>) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<h, t, rest :: binary>>, _) when h in ?A..?Z and not (t in ?A..?Z or t == ?.) do
    <<?_, to_lower_char(h), t>> <> do_underscore(rest, t)
  end

  defp do_underscore(<<h, t :: binary>>, prev) when h in ?A..?Z and not prev in ?A..?Z do
    <<?_, to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<?., t :: binary>>, _) do
    <<?/>> <> underscore(t)
  end

  defp do_underscore(<<h, t :: binary>>, _) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<>>, _) do
    <<>>
  end

  defp to_lower_char(char) when char in ?A..?Z, do: char + 32
  defp to_lower_char(char), do: char
end
