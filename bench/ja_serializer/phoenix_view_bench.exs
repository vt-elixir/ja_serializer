defmodule JaSerializer.PhoenixViewBench do
  use Benchfella

  @big 1..20
       |> Enum.map(&{String.to_atom("key_#{&1}"), &1})
       |> Enum.into(%{})

  @small 1..5
         |> Enum.map(&{String.to_atom("key_#{&1}"), &1})
         |> Enum.into(%{})

  defmodule BenchView do
    use JaSerializer.PhoenixView

    attributes [:key_1, :key_2, :key_3, :key_4, :key_5]
  end

  bench "attributes map small data",
    [context: @small],
    do: BenchView.attributes(context, nil)

  bench "attributes map big data",
    [context: @big],
    do: BenchView.attributes(context, nil)

  bench "render index small data",
    [context: @small],
    do: BenchView.render("index.json-api", data: context)

  bench "render index map big data",
    [context: @big],
    do: BenchView.render("index.json-api", data: context)

end
