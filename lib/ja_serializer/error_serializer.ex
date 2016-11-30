defmodule JaSerializer.ErrorSerializer do
  @moduledoc """
  A super basic wrapper for formatting jsonapi errors.

  Takes a map (or list of maps) with the following keys:

      :id :links :about :status :code :title :detail :source :meta

  See http://jsonapi.org/format/#error-objects for more on errors.
  """

  alias JaSerializer.Builder.TopLevel
  alias JaSerializer.Formatter

  def format(error), do: format(error, %{})
  def format(error, conn), do: format(error, conn, [])
  def format(errors, _conn, _opts) when is_list(errors) do
    errors = errors |> Enum.map(&format_one/1)
    %TopLevel{errors: errors} |> Formatter.format
  end
  def format(error, _conn, _opts) do
    errors = error
    |> format_one
    |> List.wrap

    %TopLevel{errors: errors} |> Formatter.format
  end

  @error_fields ~w(id links about status code title detail source meta)a
  defp format_one(error) do
    Dict.take(error, @error_fields)
  end
end
