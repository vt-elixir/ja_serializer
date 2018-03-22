if Code.ensure_loaded?(Phoenix) do
  defmodule Mix.Tasks.JaSerializer.Gen.PhoenixApi do
    use Mix.Task

    @shortdoc "Generates a controller and model for a JSON API based resource"

    @moduledoc """
    Generates a Phoenix resource.

        mix ja_serializer.gen.phoenix_api User users name:string age:integer

    The first argument is the module name followed by
    its plural name (used for resources and schema).

    The generated resource will contain:

      * a model in web/models
      * a view in web/views
      * a controller in web/controllers
      * a migration file for the repository
      * test files for generated model and controller

    If you already have a model, the generated model can be skipped
    with `--no-model`. Read the documentation for `phoenix.gen.model`
    for more information on attributes and namespaced resources.
    """
    def run(args) do
      switches = [binary_id: :boolean, model: :boolean]

      {opts, parsed, _} = OptionParser.parse(args, switches: switches)
      [singular, plural | attrs] = validate_args!(parsed)

      default_opts = Application.get_env(:phoenix, :generators, [])
      opts = Keyword.merge(default_opts, opts)

      attrs    = Mix.Phoenix.attrs(attrs)
      refs     = references(attrs)
      non_refs = non_references(attrs) ++ [:inserted_at, :updated_at] |> Enum.map(fn(x) -> Atom.to_string(x) end)
      binding  = Mix.Phoenix.inflect(singular)
      path     = binding[:path]
      route    = String.split(path, "/") |> Enum.drop(-1) |> Kernel.++([plural]) |> Enum.join("/")
      binding  = binding ++ [plural: plural, route: route,
                             binary_id: opts[:binary_id],
                             attrs: attrs, params: Mix.Phoenix.params(attrs),
                             refs: refs, non_refs: non_refs]

      Mix.Phoenix.check_module_name_availability!(binding[:module] <> "Controller")
      Mix.Phoenix.check_module_name_availability!(binding[:module] <> "View")

      files = [
        {:eex, "controller.ex",       "web/controllers/#{path}_controller.ex"},
        {:eex, "view.ex",             "web/views/#{path}_view.ex"},
        {:eex, "controller_test.exs", "test/controllers/#{path}_controller_test.exs"},
      ]

      unless File.exists?("web/views/changeset_view.ex") do
        Mix.Phoenix.copy_from paths(), "priv/templates/phoenix.gen.json", "", binding, [{:eex, "changeset_view.ex", "web/views/changeset_view.ex"}]
      end

      Mix.Phoenix.copy_from paths(), "priv/templates/ja_serializer.gen.phoenix_api", "", binding, files

      instructions = compile_instructions(route, binding, refs)

      if opts[:model] != false do
        Mix.Task.run "phoenix.gen.model", ["--instructions", instructions|args]
      else
        Mix.shell.info instructions
      end
    end

    defp paths do
      [
        ".",
        Mix.Project.deps_path |> Path.join("..") |> Path.expand,
        :ja_serializer,
        :phoenix
      ]
    end

    defp compile_instructions(route, binding, []) do
      """

      Add the resource to your api scope in web/router.ex:

          resources "/#{route}", #{binding[:scoped]}Controller, except: [:new, :edit]

      """
    end

    defp compile_instructions(route, binding, refs) do
      compile_instructions(route, binding, []) <> """
      Add

        + scoped resource in web/router.ex
        + has_many associations in web/models
        + has_many associations in web/views

      For:

        #{inspect(Enum.map(refs, &(&1 <> "s")))}

      """
    end

    defp validate_args!([_, plural | _] = args) do
      cond do
        String.contains?(plural, ":") ->
          raise_with_help()
        plural != Phoenix.Naming.underscore(plural) ->
          Mix.raise "expected the second argument, #{inspect plural}, to be all lowercase using snake_case convention"
        true ->
          args
      end
    end

    defp validate_args!(_) do
      raise_with_help()
    end

    defp raise_with_help do
      Mix.raise """
      mix phoenix.gen.json_api expects both singular and plural names
      of the generated resource followed by any number of attributes:

          mix phoenix.gen.json_api User users name:string
      """
    end

    defp references(attrs) do
      rv = for {k, v} <- attrs do
        references_strings({k, v})
      end

      rv |> Enum.reject(fn(x) -> is_nil(x) end)
    end

    defp references_strings({k, v}) when is_tuple(v), do: Atom.to_string(k) |> String.replace_trailing("_id", "")
    defp references_strings(_),                       do: nil

    defp non_references(attrs) do
      rv = for {k, v} <- attrs do
        non_references_strings({k, v})
      end

      rv |> Enum.reject(fn(x) -> is_nil(x) end)
    end

    defp non_references_strings({_k, v}) when is_tuple(v), do: nil
    defp non_references_strings({k, _v}),                  do: k

  end
end
