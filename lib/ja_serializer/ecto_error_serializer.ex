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
    message = Regex.replace(~r/%{count}/, message, "#{vals[:count]}")
    %{
      source: %{ pointer: pointer_for(field) },
      detail: message
    }
  end

  defp format_each({field, message}) do
    %{
      source: %{ pointer: pointer_for(field) },
      detail: message
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
