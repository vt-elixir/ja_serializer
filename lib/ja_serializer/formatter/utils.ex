defmodule JaSerializer.Formatter.Utils do
  @moduledoc false

  @doc false
  def put_if_present(dict, key, nil), do: dict
  def put_if_present(dict, key, []),  do: dict
  def put_if_present(dict, key, ""),  do: dict
  def put_if_present(dict, key, val), do: Dict.put(dict, key, val)

  @doc false
  def array_to_hash(nil), do: nil
  def array_to_hash(structs) do
    Enum.reduce structs, %{}, fn(struct, results) ->
      {key, val} = JaSerializer.Formatter.format(struct)
      Map.put(results, key, val)
    end
  end


  @doc false
  def dasherize(atom) when is_atom(atom) do
    atom |> Atom.to_string |> dasherize
  end

  # TODO
  def dasherize(binary) do
    binary
  end
end
