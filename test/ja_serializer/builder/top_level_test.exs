defmodule JaSerializer.Builder.TopLevelTest do
  use ExUnit.Case

  defmodule PersonSerializer do
    use JaSerializer
    attributes([:first_name])

    def preload(%TestModel.Person{} = data, _conn, _opts) do
      %{data | last_name: "preloaded"}
    end

    def preload(data, _conn, _opts) do
      Enum.map(data, &%{&1 | last_name: "preloaded"})
    end
  end

  test "pagination with scrivener" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}

    page = %Scrivener.Page{
      entries: [p1],
      page_number: 10,
      page_size: 20,
      total_pages: 30
    }

    context = %{
      data: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: %{}
    }

    results = JaSerializer.Builder.TopLevel.build(context)
    [data] = results.data
    links = Enum.map(results.links, & &1.type) |> Enum.sort()
    assert data.id == "p1"
    assert :first in links
    assert :prev in links
    assert :self in links
    assert :next in links
    assert :last in links
  end

  test "top level meta support" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}

    context = %{
      data: p1,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: %{meta: %{author: "Dohn Joe"}}
    }

    assert %{meta: meta} = JaSerializer.Builder.TopLevel.build(context)
    assert meta == %{author: "Dohn Joe"}
  end

  test "preload hook is called when building individual records" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}

    context = %{
      data: p1,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: %{}
    }

    assert %{data: data} = JaSerializer.Builder.TopLevel.build(context)
    assert data.data.last_name == "preloaded"
  end

  test "preload hook is called when building multiple records" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    p2 = %TestModel.Person{id: "p2", first_name: "p2"}

    context = %{
      data: [p1, p2],
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: %{}
    }

    assert %{data: [b1, b2]} = JaSerializer.Builder.TopLevel.build(context)
    assert b1.data.last_name == "preloaded"
    assert b2.data.last_name == "preloaded"
  end
end
