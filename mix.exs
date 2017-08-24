defmodule JaSerializer.Mixfile do
  use Mix.Project

  def project do
    [app: :ja_serializer,
     version: "0.8.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: Mix.env != :test,
     source_url: "https://github.com/AgilionApps/ja_serializer",
     package: package(),
     description: description(),
     deps: deps()]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :inflex, :plug, :ecto, :poison]]
  end

  defp deps do
    [{:inflex, "~> 1.8"},
     {:plug, "~> 1.4"},
     {:ecto, "~> 2.0"},
     {:poison, "~> 1.4 or ~> 3.0"},
     {:earmark, "~> 1.0", only: :dev},
     {:inch_ex, "~> 0.5", only: :docs},
     {:scrivener, "~> 2.0", optional: true},
     {:ex_doc, "~> 0.16", only: :dev}]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Alan Peabody"],
      links: %{
        "GitHub" => "https://github.com/AgilionApps/ja_serializer"
      },
    ]
  end

  defp description do
    """
    A serialization library implementing the jsonapi.org 1.0 spec suitable for
    use building JSON APIs in Pheonix, Relax, or any other plug based
    framework/library.
    """
  end
end
