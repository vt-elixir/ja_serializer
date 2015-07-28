defmodule JaSerializer.Formatter.UtilsTest do
  use ExUnit.Case
  alias JaSerializer.Formatter.Utils

  test "formatting keys - dasherize - by default" do
    assert Utils.format_key(:blog_post) == "blog-post"
    assert Utils.format_key("approved_comments") == "approved-comments"
  end

  test "formatting keys - dasherize - via config" do
    Application.put_env(:ja_serializer, :key_format, :dasherized)
    assert Utils.format_key(:blog_post) == "blog-post"
    assert Utils.format_key("approved_comments") == "approved-comments"
    Application.delete_env(:ja_serializer, :key_format)
  end

  test "formatting keys - underscore" do
    Application.put_env(:ja_serializer, :key_format, :underscored)
    assert Utils.format_key(:blog_post) == "blog_post"
    assert Utils.format_key("approved_comments") == "approved_comments"
    Application.delete_env(:ja_serializer, :key_format)
  end

  def smasherize(key), do: String.replace(key, ~r/_/, "")

  test "formatting keys - custom" do
    Application.put_env(:ja_serializer, :key_format, {:custom, JaSerializer.Formatter.UtilsTest, :smasherize})
    assert Utils.format_key(:blog_post) == "blogpost"
    assert Utils.format_key("approved_comments") == "approvedcomments"
    Application.delete_env(:ja_serializer, :key_format)
  end

end
