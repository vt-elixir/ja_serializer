defmodule JaSerializer.Builder.UtilsTest do
  use ExUnit.Case
  alias JaSerializer.Builder.Utils

  describe "safe_atom_list/1" do
    test "split string and convert to existing atoms" do
      assert Utils.safe_atom_list("atom1,atom2") == [:atom1, :atom2]
    end
  end

  describe "normalize_includes/1" do
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
end
