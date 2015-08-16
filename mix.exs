defmodule JaSerializer.Mixfile do
  use Mix.Project

  def project do
    [app: :ja_serializer,
     version: "0.1.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/AgilionApps/ja_serializer",
     package: package,
     description: description,
     deps: deps]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:inflex, "~> 1.4"},
      {:poison, "~> 1.4", only: :test},
      {:plug, "~> 1.0", only: :test},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev}]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      contributors: ["Alan Peabody"],
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
