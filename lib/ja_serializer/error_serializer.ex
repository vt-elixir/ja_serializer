defmodule JaSerializer.ErrorSerializer do
  @moduledoc """
  A super basic wrapper for formatting jsonapi errors.

  Takes a map (or list of maps) with the following keys:

      :id :links :about :status :code :title :detail :source :meta

  See http://jsonapi.org/format/#error-objects for more on errors.
  """

  def format(error), do: format(error, %{})
  def format(error, conn), do: format(error, conn, [])
  def format(errors, _conn, _opts) when is_list(errors) do
    errors
    |> Enum.map(&format_one/1)
    |> as_json
  end
  def format(error, _conn, _opts) do
    error
    |> format_one
    |> List.wrap
    |> as_json
  end

  @error_fields ~w(id links about status code title detail source meta)a
  defp format_one(error) do
    Dict.take(error, @error_fields)
  end

  defp as_json(errors), do: %{"errors" => errors}
end
