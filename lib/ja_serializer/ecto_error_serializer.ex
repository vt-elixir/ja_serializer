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
  def format(%{__struct__: Ecto.Changeset} = cs, o), do: format(cs.errors, o)
  def format(errors, opts) do
    errors
    |> Enum.map(&(format_each(&1, opts[:opts])))
    |> JaSerializer.ErrorSerializer.format
  end
  def format(%{__struct__: Ecto.Changeset} = cs, _c, o), do: format(cs.errors, o)

  defp format_each({field, {message, vals}}, opts) do
    # See https://github.com/elixir-ecto/ecto/blob/34a1012dd1f6d218c0183deb512b6c084afe3b6f/lib/ecto/changeset.ex#L1836-L1838
    title = Enum.reduce(vals, message, fn {key, value}, acc ->
      case key do
        :type -> acc
        _ -> String.replace(acc, "%{#{key}}", to_string(value))
      end
    end)

    %{
      source: %{pointer: pointer_for(field)},
      title: title,
      detail: "#{Utils.humanize(field)} #{title}"
    } |> merge_opts(opts)
  end

  defp format_each({field, message}, opts) do
    %{
      source: %{pointer: pointer_for(field)},
      title: message,
      detail: "#{Utils.humanize(field)} #{message}"
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
  defp pointer_for(field) do
    case Regex.run(~r/(.*)_id$/, to_string(field)) do
      nil      -> "/data/attributes/#{Utils.format_key(field)}"
      [_, rel] -> "/data/relationships/#{Utils.format_key(rel)}"
    end
  end
end
