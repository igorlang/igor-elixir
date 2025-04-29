defmodule Igor.Json.Test do
  use ExUnit.Case
  doctest Igor.Json

  test "parse" do
    dict = %{"1" => "a", "2" => "b", "3" => "c"}
    json = %{"int" => 1, "string" => "test", "bool.true" => true, "bool.false" => false, "float" => 1.2, "list" => [1, 2, 3], "dict" => dict}
    assert Igor.Json.parse_field(json, "int", :int) === 1
    assert Igor.Json.parse_field(json, "int", :float) === 1.0
    assert Igor.Json.parse_field(json, "float", :double) === 1.2
    assert Igor.Json.parse_field(json, "bool.true", :boolean) === true
    assert Igor.Json.parse_field(json, "bool.false", :boolean) === false
    assert Igor.Json.parse_field(json, "string", :string) === "test"
    assert Igor.Json.parse_field(json, "string", :atom) === :test
    assert Igor.Json.parse_field(json, "list", {:list, :int}) === [1,2,3]
    assert Igor.Json.parse_field(json, "dict", {:map, :int, :string}) === %{1 => "a", 2 => "b", 3 => "c"}
    assert Igor.Json.parse_field(json, "none", :int, 5) === 5
  end

  test "test2" do
    complex = {2, 4.5, nil, "24", "opt"}
    json = ProtocolTupleRecord.Complex.to_json!(complex)
    assert ProtocolTupleRecord.Complex.from_json!(json) === complex
  end
end
