defmodule JaSerializer.Mixfile do
  use Mix.Project

  def project do
    [app: :ja_serializer,
     version: "0.11.2",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: Mix.env != :test,
     source_url: "https://github.com/vt-elixir/ja_serializer",
     package: package,
     description: description,
     deps: deps]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :inflex, :plug, :poison]]
  end

  defp deps do
    [
      {:inflex, "~> 1.4"},
      {:plug, "> 1.0.0"},
      {:poison, "~> 1.4 or ~> 2.0"},
      {:ecto, "~> 1.1 or ~> 2.0", only: :test},
      {:earmark, "~> 0.1", only: :dev},
      {:inch_ex, "~> 0.4", only: :docs},
      {:scrivener, "~> 1.2 or ~> 2.0", optional: true},
      {:benchfella, "~> 0.3.0", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev},
      {:dialyxir, "~> 0.3.5", only: :dev},
      {:credo, "~> 0.4.11", only: :dev},
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Alan Peabody"],
      links: %{
        "GitHub" => "https://github.com/vt-elixir/ja_serializer"
      },
    ]
  end

  defp description do
    """
    A serialization library implementing the jsonapi.org 1.0 spec suitable for
    use building JSON APIs in Pheonix and any other Plug based framework or app.
    """
  end
end
