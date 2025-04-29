defmodule Igor.Strings do

  def parse(value, {:option, type}), do: parse(value, type, nil)
  def parse(nil, _type), do: raise ArgumentError, message: "undefined value"
  def parse(value, type) when is_binary(value), do: parse_value(value, type)

  def parse(nil, _type, default), do: default
  def parse(value, type, _default), do: parse_value(value, type)

  def format(value, {:option, type}), do: format_value(value, type);
  def format(value, type), do: format_value(value, type)

  def parse_value("true", :boolean), do: true
  def parse_value("false", :boolean), do: false
  def parse_value(string, :sbyte), do: String.to_integer(string)
  def parse_value(string, :byte), do: String.to_integer(string)
  def parse_value(string, :short), do: String.to_integer(string)
  def parse_value(string, :ushort), do: String.to_integer(string)
  def parse_value(string, :int), do: String.to_integer(string)
  def parse_value(string, :uint), do: String.to_integer(string)
  def parse_value(string, :long), do: String.to_integer(string)
  def parse_value(string, :ulong), do: String.to_integer(string)
  def parse_value(string, :float), do: string_to_float(string)
  def parse_value(string, :double), do: string_to_float(string)
  def parse_value(string, :string), do: string
  def parse_value(string, :binary), do: string
  def parse_value(string, :atom), do: String.to_atom(string)
  def parse_value(string, {:list, separator, item_type}), do: for item <- String.split(string, separator, global: true), do: parse_value(item, item_type)
  def parse_value(string, {:custom, module}), do: module.from_string!(string)

  def format_value(true, :boolean), do: "true";
  def format_value(false, :boolean), do: "false";
  def format_value(value, :sbyte) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :byte) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :short) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :ushort) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :int) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :uint) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :long) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :ulong) when is_integer(value), do: Integer.to_string(value)
  def format_value(value, :float) when is_number(value), do: Float.to_string(value)
  def format_value(value, :double) when is_number(value), do: Float.to_string(value)
  def format_value(value, :binary) when is_binary(value), do: value
  def format_value(value, :string) when is_binary(value), do: value
  def format_value(value, :atom) when is_atom(value), do: Atom.to_string(value)
  def format_value(value, {:list, separator, item_type}) when is_list(value), do: Enum.join(for item <- value do format_value(item, item_type) end, separator)

  defp string_to_float(string) do
    {value, ""} = Float.parse(string)
    value
  end

end
