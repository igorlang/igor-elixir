defmodule Igor.Http.Test do
  use ExUnit.Case
  doctest Igor.Http

  test "format_query" do
    query = Igor.Http.compose_query([{"a", 1, :int}, {"b", true, :boolean}])
    assert "#{query}" === "a=1&b=true"
  end

end
