defmodule JaSerializer.Params do
  @moduledoc """
  Functions to help when working with json api params.
  """

  @doc """
  Takes the entire params passed in and merges relationships and attributes.

  Note, this expects to recieve the json api "data" param.

  Example functionality:

      JaSerializer.Params.to_attributes(%{
        "type" => "person",
        "attributes" => %{"first" => "Jane", "last" => "Doe", "type" => "anon"},
        "relationships" => %{"user" => %{"data" => %{"id" => 1}}}
      })
      %{
        "first" => "Jane",
        "last" => "Doe",
        "type" => "anon",
        "user_id" => 1
      }

  Example usage:

      def create(conn, %{"data" => data}) do
        %Comment{}
        |> Comment.changeset(create_params(data))
        |> Repo.insert
        |> case do
          {:ok, my_model} ->
            # etc
          {:error, changeset} -> etc
            # etc
        end
      end

      defp create_params(data) do
        data
        |> JaSerializer.Params.to_attributes
        |> Map.take(["name", "body", "post_id"])
      end

  """
  def to_attributes(%{"data" => data}), do: to_attributes(data)
  def to_attributes(data) when is_map(data) do
    data
    |> parse_relationships
    |> Map.merge(data["attributes"] || %{})
    |> Map.put_new("type", data["type"])
  end

  defp parse_relationships(%{"relationships" => nil}) do
    %{}
  end

  defp parse_relationships(%{"relationships" => rels}) do
    Enum.reduce rels, %{}, fn
      ({name, %{"data" => nil}}, rel) ->
        Map.put(rel, "#{name}_id", nil)
      ({name, %{"data" => %{"id" => id}}}, rel) ->
        Map.put(rel, "#{name}_id", id)
      ({name, %{"data" => ids}}, rel) when is_list(ids) ->
        Map.put(rel, "#{name}_ids", Enum.map(ids, &(&1["id"])))
    end
  end

  defp parse_relationships(_) do
    %{}
  end
end
