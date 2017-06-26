defmodule JaSerializer.PhoenixViewBench do
  use Benchfella

  @big 1..20
       |> Enum.map(&{String.to_atom("key_#{&1}"), &1})
       |> Enum.into(%{})

  @small 1..5
         |> Enum.map(&{String.to_atom("key_#{&1}"), &1})
         |> Enum.into(%{})

  defmodule BenchSmallView do
    use JaSerializer.PhoenixView

    attributes [:key_1,:key_2,:key_3,:key_4,:key_5]
  end

  defmodule BenchBigView do
    use JaSerializer.PhoenixView

    attributes [:key_1,:key_2,:key_3,:key_4,:key_5,
                :key_6,:key_7,:key_8,:key_9,:key_10,
                :key_11,:key_12,:key_13,:key_14,:key_15,
                :key_16,:key_17,:key_18,:key_19,:key_20]
  end

  bench "attributes map small data",
    [context: @small],
    do: BenchSmallView.attributes(context, nil)

  bench "attributes map big data",
    [context: @big],
    do: BenchBigView.attributes(context, nil)

  bench "render index one item small data",
    [context: @small],
    do: BenchSmallView.render("index.json-api", data: context)

  bench "render index one item map big data",
    [context: @big],
    do: BenchBigView.render("index.json-api", data: context)

  bench "render index 25 items small data",
    [context: 1..25 |> Enum.map(fn _ -> @small end) ],
    do: BenchSmallView.render("index.json-api", data: context)

  bench "render index 25 items map big data",
    [context: 1..25 |> Enum.map(fn _ -> @big end)],
    do: BenchBigView.render("index.json-api", data: context)


end
