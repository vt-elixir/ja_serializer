if Code.ensure_loaded?(Ecto) do
  defmodule JaSerializer.EctoErrorSerializer do
    alias JaSerializer.Formatter.Utils

    @moduledoc """

    The EctoErrorSerializer is used to transform Ecto changeset errors to JSON API standard
    error objects.

    If a changeset is past in without optional error members then the object returned will
    only contain: source, title, and detail.

    ```
    %{"errors" => [
       %{
         source: %{pointer: "/data/attributes/monies"},
         title: "must be more than 10",
         detail: "Monies must be more than 10"
        }
      ]
    }

    ```

    Additional error members can be set by passing in an options list.
    These include: id, status, code, meta, and links.

    For more information on the JSON API standard for handling error objects check_origin:
    [jsonapi.org](http://jsonapi.org/examples/#error-objects)

    """

    def format(errors), do: format(errors, [])
    def format(errors, conn) when is_map(conn), do: format(errors, [])
    def format(%Ecto.Changeset{} = cs, opts) do
      errors =
        Ecto.Changeset.traverse_errors(cs, fn({msg, validation_opts}) ->
          Enum.reduce(validation_opts, msg, fn {key, value}, acc ->
            # Some error options cannot be represented as a string (noteably tuples), so we
            # ignore them when modifying the message so that it doesn't break `String.replace/3`.
            case String.Chars.impl_for(value) do
              nil -> acc
              _impl -> String.replace(acc, "%{#{key}}", to_string(value))
            end
          end)
        end)

      format(errors, opts)
    end
    def format(errors, opts) do
      errors
      |> Enum.map(fn({field, messages}) -> format_each({[field], messages}, opts[:opts]) end)
      |> List.flatten
      |> JaSerializer.ErrorSerializer.format
    end
    def format(%Ecto.Changeset{} = cs, _conn, opts), do: format(cs, opts)

    defp format_each({parent_fields, nested_errors}, opts) when is_map(nested_errors) do
      Enum.map(nested_errors, fn({field, messages}) ->
        format_each({[field | parent_fields], messages}, opts)
      end)
    end
    defp format_each({fields, messages}, opts) when is_list(messages) do
      Enum.map(messages, fn(message) ->
        format_field_errors(fields, message, opts)
      end)
    end

    defp format_field_errors(fields, message, opts) do
      %{
        source: %{pointer: pointer_for(fields)},
        title: message,
        detail: "#{Utils.humanize(hd(fields))} #{message}"
      } |> merge_opts(opts)
    end

    defp merge_opts(error, nil), do: error
    defp merge_opts(error, opts) when is_list(opts) do
      opts = Enum.into(opts, %{})
      Map.merge(error, opts)
    end
    defp merge_opts(error, _opts), do: error

    # Assumes relationship name is the same as the field name without the id.
    # This is a fairly large and incorrect assumption, but until we have better
    # ideas this will work for most relationships.
    defp pointer_for([field | parent_fields] = fields) do
      case Regex.run(~r/(.*)_id$/, to_string(field)) do
        nil      -> "/data/attributes/#{format_fields(fields)}"
        [_, rel] -> "/data/relationships/#{format_fields([rel | parent_fields])}"
      end
    end

    defp format_fields(fields) do
      fields
      |> Enum.reverse
      |> Enum.map(&Utils.format_key/1)
      |> Enum.join("/")
    end
  end
end
