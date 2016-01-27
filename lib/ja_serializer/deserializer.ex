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
    def call(conn, _opts), do: Map.put(conn, :params, format_params(conn.params))

    defp format_params(%{"data" => %{"type" => _}} = params) do
      {resource, other_params} = Map.pop(params, "data")
      Map.merge(do_format_resource(resource), do_deep_format_keys(other_params))
    end
    defp format_params(params) when is_map(params), do: do_deep_format_keys(params)

    def do_format_resource(resource) do
      Map.merge(resource, %{
        "data" => %{
          "type" => resource["type"],
          "attributes" => do_format_keys(resource["attributes"]),
          "relationships" => do_format_keys(resource["relationships"])
        }
      })
    end

    def do_deep_format_keys(map) when is_map(map) do
      Enum.reduce(map, %{}, &do_format_key_value/2)
    end

    defp do_format_key_value({key, value}, accumulator) when is_map(value) do
      Map.put(accumulator, format_key(key), do_deep_format_keys(value))
    end
    defp do_format_key_value({key, value}, accumulator) do
      Map.put(accumulator, format_key(key), value)
    end

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
