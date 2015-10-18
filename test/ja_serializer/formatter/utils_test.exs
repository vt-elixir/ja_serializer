defmodule JaSerializer.Formatter.UtilsTest do
  use ExUnit.Case
  alias JaSerializer.Formatter.Utils

  test "formatting keys - dasherize - by default" do
    assert Utils.format_key(:blog_post) == "blog-post"
    assert Utils.format_key("approved_comments") == "approved-comments"
  end

  test "formatting keys - dasherize" do
    assert Utils.format_key(:blog_post) == "blog-post"
    assert Utils.do_format_key("approved_comments", :dasherized) == "approved-comments"
  end

  test "formatting keys - underscore" do
    assert Utils.do_format_key("approved_comments", :underscored) == "approved_comments"
  end

  def smasherize(key), do: String.replace(key, ~r/_/, "")

  test "formatting keys - custom" do
    custom = {:custom, JaSerializer.Formatter.UtilsTest, :smasherize}
    assert Utils.do_format_key("approved_comments", custom) == "approvedcomments"
  end
end
