defmodule Foo do
  defstruct [:id, :bars]
end

defmodule Bar do
  defstruct [:id, :foo]
end

defmodule BarSerializer do
  use JaSerializer.Serializer

  def type, do: "bar"

  attributes([])

  has_one(
    :foo,
    serializer: FooSerializer
  )
end

defmodule FooSerializer do
  use JaSerializer.Serializer

  def type, do: "foo"

  attributes([])

  has_many(
    :bars,
    include: true,
    serializer: BarSerializer
  )
end

defmodule Benchmark do
  def generate(a, b) do
    for m <- 0..a do
      bars =
        for n <- 0..b do
          %Bar{id: n, foo: %Foo{id: m, bars: []}}
        end

      %Foo{id: m, bars: bars}
    end
  end

  def tc_avg(mod, fun, args, iters \\ 10) do
    {z, _} = :timer.tc(mod, fun, args)

    {m, _} =
      Enum.reduce(0..iters, {z, 1}, fn _, {m, n} ->
        IO.write(:stderr, ".")
        {t, _} = :timer.tc(mod, fun, args)
        {m + (t - m) / (n + 1), n + 1}
      end)

    IO.write(:stderr, "\n")
    m
  end

  def humanize(n) do
    Enum.reduce_while(["ms", "s"], {n, "us"}, fn n_scale, {n, o_scale} ->
      if n > 1000 do
        {:cont, {n / 1000, n_scale}}
      else
        {:halt, {n, o_scale}}
      end
    end)
  end

  defp parse_int!(n) do
    case Integer.parse(n, 10) do
      {n, ""} -> n
    end
  end

  def run do
    [x, y] = System.argv() |> Enum.map(&parse_int!/1)

    tc_avg(FooSerializer, :format, [generate(x, y)], 25)
    |> humanize
  end
end

Benchmark.run() |> IO.inspect()
