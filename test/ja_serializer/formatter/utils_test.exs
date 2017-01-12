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

  test "Will humanize a string" do
    assert Utils.humanize("title") == "Title"
    assert Utils.humanize("first_name") == "First name"
  end

  test "Will omit the _id portion of a string when humanizing" do
    assert Utils.humanize("user_id") == "User"
  end

  test "Will humanize an atom" do
    assert Utils.humanize(:title) == "Title"
  end

  def smasherize(key), do: String.replace(key, ~r/_/, "")

  test "formatting keys - custom" do
    custom = {:custom, JaSerializer.Formatter.UtilsTest, :smasherize, nil}
    assert Utils.do_format_key("approved_comments", custom) == "approvedcomments"
  end

  test "formatting type - dasherize - by default" do
    assert Utils.format_type("BlogPost") == "blog-post"
    assert Utils.format_type("ApprovedComments") == "approved-comments"
  end

  test "formatting type - dasherize" do
    assert Utils.format_type("BlogPost") == "blog-post"
    assert Utils.do_format_type("ApprovedComments", :dasherized) == "approved-comments"
  end

  test "formatting type - underscored" do
    assert Utils.do_format_type("ApprovedComments", :underscored) == "approved_comments"
  end

  test "formatting type - custom" do
    custom = {:custom, JaSerializer.Formatter.UtilsTest, :smasherize, nil}
    assert Utils.do_format_type("approved_comments", custom) == "approvedcomments"
  end
end
