defmodule JaSerializer.ParamsTest do
  use ExUnit.Case, async: true

  import JaSerializer.Params, only: [to_attributes: 1]

  test "no relationships" do
    input = %{"data" => %{
      "type" => "person",
      "attributes" => %{"first" => "Jane", "last" => "Doe"}
    }}
    output = %{
      "first" => "Jane",
      "last" => "Doe",
      "type" => "person"
    }
    assert to_attributes(input) == output
  end

  test "singular relationship" do
    input = %{"data" => %{
      "type" => "person",
      "attributes" => %{"first" => "Jane", "last" => "Doe", "type" => "anon"},
      "relationships" => %{"user" => %{"data" => %{"id" => 1}}}
    }}
    output = %{
      "first" => "Jane",
      "last" => "Doe",
      "type" => "anon",
      "user_id" => 1
    }
    assert to_attributes(input) == output
  end

  test "plural relationships" do
    input = %{"data" => %{
      "type" => "person",
      "attributes" => %{"first" => "Jane", "last" => "Doe", "type" => "anon"},
      "relationships" => %{"user" => %{"data" => [%{"id" => 1}, %{"id" => 2}]}}
    }}
    output = %{
      "first" => "Jane",
      "last" => "Doe",
      "type" => "anon",
      "user_ids" => [1, 2]
    }
    assert to_attributes(input) == output
  end
end
