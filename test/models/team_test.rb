require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "team name sanitazion" do
    nobr = "\u00A0"
    assert_equal "Foo#{nobr}/ Bar", Team.sanitize_name("Foo / Bar")
    assert_equal "Foo#{nobr}/ Bar", Team.sanitize_name("Foo#{nobr}/#{nobr}Bar")
    assert_equal "Foo/Bar", Team.sanitize_name("Foo/Bar")
    assert_equal "Foo/#{nobr}Bar", Team.sanitize_name("Foo/ Bar")
    assert_equal "Foo#{nobr}/Bar", Team.sanitize_name("Foo /Bar")

    assert_equal "Foo#{nobr}/ Bar", Team.sanitize_name("Foo/Bar", slashes_had_no_whitespace: true)
    assert_equal "Foo#{nobr}/ Bar", Team.sanitize_name("Foo / Bar", slashes_had_no_whitespace: true)
    assert_equal "Foo#{nobr}/ Bar", Team.sanitize_name("Foo/ Bar", slashes_had_no_whitespace: true)
    assert_equal "Foo#{nobr}/ Bar", Team.sanitize_name("Foo /Bar", slashes_had_no_whitespace: true)

  end
end
