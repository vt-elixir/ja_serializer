defmodule JaSerializer.Deserializer do
  @moduledoc """
  This plug "deserializes" params to underscores.

  For example these params:

      %{
        "data" => %{
          "attributes" => %{
            "foo-bar" => true
          }
        }
      }

  are transformed to:

      %{
        "data" => %{
          "attributes" => %{
            "foo_bar" => true
          }
        }
      }

  ## Usage

  Just include in your plug stack _after_ a json parser:

      plug Plug.Parsers, parsers: [:json], json_decoder: Poison
      plug JaSerializer.Deserializer

  """

  @behaviour Plug

  def init(opts), do: opts
  def call(conn, _opts) do 
    Map.put(conn, :params, JaSerializer.ParamParser.parse(conn.params))
  end
end
