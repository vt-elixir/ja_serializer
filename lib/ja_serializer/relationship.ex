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

  defmodule HasMany do
    @moduledoc """
    Struct to represent a HasMany relationship.

    The fields are:

      * `serializer`  - A Serializer (often a PhoenixView) implementing the JaSerializer.Serializer behaviour.
      * `include`     - Should this relationship be included (sideloaded) by default. Overriden by `include` opt to JaSerializer.format/4
      * `data`        - A list of structs representing the data.
      * `identifiers` - Should "resource identifiers be included, options are `:when_included` and `:always`. Defaults to `:when_included`
      * `links`       - A keyword list of links, `self` and `related` are most common.
      * `name`        - Name of the relationship, automatically set.

    Used when defining relationships without the DSL using the
    JaSerializer.relationships/2 callback. For example:

        def relationships(article, _conn) do
          %{
            comments: %HasMany{
              serializer:  MyApp.CommentView,
              include:     true,
              data:        article.comments,
            }
          }
        end

    See JaSerializer.DSL.has_many/2 for information on defining different types
    of relationships.
    """
    defstruct [
      links:       [],
      type:        nil,
      serializer:  nil,
      include:     false,
      data:        nil,
      identifiers: :when_included,
      name:        nil
    ]

    @doc false
    def from_dsl(name, dsl_opts) do
      %__MODULE__{
        links:       dsl_opts[:links] || [],
        type:        dsl_opts[:type],
        serializer:  dsl_opts[:serializer],
        include:     dsl_opts[:include],
        data:        dsl_opts[:data] || name,
        identifiers: dsl_opts[:identifiers] || :when_included,
        name:        name
      }
    end
  end

  defmodule HasOne do
    @moduledoc """
    Struct representing a HasOne (or belongs to) relationship.

    The fields are:

      * `serializer`  - A Serializer (often a PhoenixView) implementing the JaSerializer.Serializer behaviour.
      * `include`     - Should this relationship be included (sideloaded) by default. Overriden by `include` opt to JaSerializer.format/4
      * `data`        - A struct representing the data for serialization.
      * `identifiers` - Should "resource identifiers be included, options are `:when_included` and `:always`. Defaults to `:when_included`
      * `links`       - A keyword list of links, `self` and `related` are most common.
      * `name`        - Name of the relationship, automatically set.


    Used when defining relationships without the DSL using the
    JaSerializer.relationships/2 callback. For example:

        def relationships(article, _conn) do
          %{
            comments: %HasOne{
              serializer:  MyApp.CommentView,
              include:     true,
              data:        article.comments,
            }
          }
        end

    See JaSerializer.DSL.has_many/2 for information on defining different types
    of relationships.
    """
    defstruct [
      links:       [],
      type:        nil,
      serializer:  nil,
      include:     false,
      data:        nil,
      identifiers: :always,
      name:        nil
    ]

    @doc false
    def from_dsl(name, dsl_opts) do
      %__MODULE__{
        links:       dsl_opts[:links] || [],
        type:        dsl_opts[:type],
        serializer:  dsl_opts[:serializer],
        include:     dsl_opts[:include],
        data:        dsl_opts[:data] || name,
        identifiers: dsl_opts[:identifiers] || :always,
        name:        name
      }
    end
  end

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
  def get_data(struct, name, opts) do
    rel = (opts[:field] || name)
    struct
    |> Map.get(rel)
    |> case do
      %{__struct__: Ecto.Association.NotLoaded} -> raise @error, rel: rel, name: name
      other -> other
    end
  end

end
