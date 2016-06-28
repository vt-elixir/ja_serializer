defmodule JaSerializer.EctoErrorSerializer do
  alias JaSerializer.Formatter.Utils

  def format(errors), do: format(errors, %{})
  def format(errors, conn), do: format(errors, conn, [])
  def format(%Ecto.Changeset{} = cs, c, o), do: format(cs.errors, c, o)
  def format(errors, _conn, _) do
    errors
    |> Enum.map(&format_each/1)
    |> JaSerializer.ErrorSerializer.format
  end

  defp format_each({field, {message, vals}}) do
    # See https://github.com/elixir-ecto/ecto/blob/34a1012dd1f6d218c0183deb512b6c084afe3b6f/lib/ecto/changeset.ex#L1836-L1838
    title = Enum.reduce vals, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end

    %{
      source: %{ pointer: pointer_for(field) },
      title: title,
      detail: "#{Utils.humanize(field)} #{title}"
    }
  end

  defp format_each({field, message}) do
    %{
      source: %{ pointer: pointer_for(field) },
      title: message,
      detail: "#{Utils.humanize(field)} #{message}"
    }
  end

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
