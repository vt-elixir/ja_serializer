defmodule JaSerializer.AssociationNotLoadedError do
  defexception [:message]

  def exception(opts) do
    msg = """
    The #{opts[:rel]} relationship returned %Ecto.Association.NotLoaded{}.

    Please pre-fetch the relationship before serialization or override the
    #{opts[:name]}/2 function in your serializer.

    Example:

        def #{opts[:name]}(struct, conn) do
          case struct.#{opts[:rel]} do
            %Ecto.Association.NotLoaded{} ->
              struct
              |> Ecto.assoc(:#{opts[:rel]})
              |> Repo.all
            other -> other
          end
        end
    """
    %JaSerializer.AssociationNotLoadedError{message: msg}
  end
end

defmodule JaSerializer.Relationship do
  @moduledoc false

  @doc false
  def default_function(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      def unquote(name)(struct, _conn) do
        JaSerializer.Relationship.get_data(struct, unquote(name), unquote(opts))
      end
      defoverridable [{name, 2}]
    end
  end

  @error JaSerializer.AssociationNotLoadedError
  # If ecto is loaded we try to load relationships appropriately
  def get_data(struct, name, opts) do
    rel = (opts[:field] || name)
    struct
    |> Map.get(rel)
    |> case do
      %Ecto.Association.NotLoaded{} -> raise @error, rel: rel, name: name
      other -> other
    end
  end
end
