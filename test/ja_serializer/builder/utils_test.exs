defmodule JaSerializer.Builder.UtilsTest do
  use ExUnit.Case
  alias JaSerializer.Builder.Utils

  test "no includes" do
    assert Utils.normalize_includes(nil) == []
    assert Utils.normalize_includes("") == []
  end

  test "shallow includes" do
    include = "include-one,include-two,three,four"

    assert Utils.normalize_includes(include) == [
             four: [],
             three: [],
             include_two: [],
             include_one: []
           ]
  end

  test "nested includes" do
    include =
      "include-one,include-one.include-two,include-one.include-two.include-three"

    assert Utils.normalize_includes(include) == [
             include_one: [include_two: [include_three: []]]
           ]
  end
end
