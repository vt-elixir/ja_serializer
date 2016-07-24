defmodule JaSerializer.ErrorSerializerTest do
  use ExUnit.Case

  alias JaSerializer.ErrorSerializer

  test "formatting one error" do
    expected = %{"errors" => [%{ title: "foo", detail: "bar"}]}
    assert expected == ErrorSerializer.format(%{title: "foo", detail: "bar"})
  end

  test "formatting a list of errors" do
    expected = %{
      "errors" => [
        %{title: "foo", detail: "baz"},
        %{title: "fu", detail: "bar"}
      ]
    }
    assert expected == ErrorSerializer.format([
      %{title: "foo", detail: "baz"},
      %{title: "fu", detail: "bar"}
    ])
  end

  test "ignore invalid fields" do
    expected = %{"errors" => [%{title: "foo"}]}
    assert expected == ErrorSerializer.format(%{title: "foo", name: "bar"})
  end
end
