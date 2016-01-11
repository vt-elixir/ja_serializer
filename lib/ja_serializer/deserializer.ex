if Code.ensure_loaded?(Plug) do
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
    def call(conn, _opts), do: Map.put(conn, :params, format_keys(conn.params))

    defp format_keys(%{"data" => data} = params) do
      Map.merge(params, %{
        "data" => %{
          "type" => data["type"],
          "attributes" => do_format_keys(data["attributes"]),
          "relationships" => do_format_keys(data["relationships"])
        }
      })
    end
    defp format_keys(params), do: params

    defp do_format_keys(map) when is_map(map) do
      Enum.reduce map, %{}, fn({k, v}, a) ->
        Map.put_new(a, format_key(k), v)
      end
    end
    defp do_format_keys(other), do: other

    #TODO: Support custom de-serialization (eg, camelcase)
    def format_key(key) do
      case Application.get_env(:ja_serializer, :key_format, :dasherized) do
        :dasherized -> dash_to_underscore(key)
        :underscored -> key
        _ -> key
      end
    end

    defp dash_to_underscore(key), do: String.replace(key, ~r/-/, "_")
  end
end
