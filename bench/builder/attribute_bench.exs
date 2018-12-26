defmodule Builder.AttributeBench do
  use Benchfella

  @big 1..20
       |> Enum.map(&{String.to_atom("key_#{&1}"), &1})
       |> Enum.into(%{})

  @small 1..5
         |> Enum.map(&{String.to_atom("key_#{&1}"), &1})
         |> Enum.into(%{})

  bench(
    "no opts to process small data",
    [context: data_no_opts(@small)],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "no opts to process big data",
    [context: data_no_opts(@big)],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "no field opts to process small data",
    [context: data_opts(@small)],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "no field opts to process big data",
    [context: data_opts(@big)],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "field opts for wrong serializer small data",
    [context: data_opts(@small, fields: %{"seabass" => "fin,scale"})],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "field opts for wrong serializer big data",
    [context: data_opts(@big, fields: %{"seabass" => "fin,scale"})],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "fields opts for correct serializer small data",
    [context: data_opts(@small, fields: %{"widget" => "key_1,key_5"})],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "fields opts for correct serializer big data",
    [context: data_opts(@small, fields: %{"widget" => "key_1,key_5"})],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "optimized opts for correct serializer small data",
    [context: data_opts(@small, fields: %{"widget" => [:key_2, :key_8]})],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  bench(
    "optimized opts for correct serializer big data",
    [context: data_opts(@big, fields: %{"widget" => [:key_2, :key_8]})],
    do: JaSerializer.Builder.Attribute.build(context)
  )

  defmodule Serializer do
    def type, do: "widget"
    def attributes(data, _), do: data
  end

  defp data_no_opts(data),
    do: %{data: data, serializer: Serializer, conn: nil}

  defp data_opts(data, opts \\ []),
    do: %{data: data, serializer: Serializer, conn: nil, opts: opts}
end
