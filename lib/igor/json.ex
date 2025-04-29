defmodule Igor.Json do

  @type type :: :boolean | :sbyte | :byte | :short | :ushort | :int | :uint | :long | :ulong | :float | :double | :binary | :string | :atom
    | {:custom, module()} | {:custom, module(), tuple()} | {:list, type()} | {:map, type(), type()} | {:option, type()}

  @type json :: term

  @spec encode!(json()) :: String.t()
  def encode!(value), do: Jason.encode!(value)

  @spec decode!(String.t()) :: json()
  def decode!(json) do
    Jason.decode!(json)
  rescue
    e in Jason.DecodeError ->
      raise Igor.DecodeError, message: "invalid_json", type: :json
  end

  @spec parse_field(json(), String.t(), type(), term()) :: term()
  def parse_field(json_object, key, type, default) when is_map(json_object) do
    case Map.get(json_object, key) do
        nil when elem(type, 0) === :option -> nil
        nil -> default
        value -> parse_value(value, type)
    end
  rescue
    e in Igor.DecodeError ->
      raise %{e | message: "invalid_#{key}", info: e.message, type: type}
    e ->
      raise Igor.DecodeError, message: "invalid_#{key}", info: Map.get(e, :message), type: type
  end

  @spec parse_field(json(), String.t(), type()) :: term()
  def parse_field(json_object, key, type) when is_map(json_object) do
    case Map.get(json_object, key) do
      nil when elem(type, 0) === :nullable -> nil
      nil -> raise Igor.DecodeError, message: "missing_#{key}", type: type
      value -> parse_value(value, type)
    end
  rescue
    e in Igor.DecodeError ->
      case e do
        %{message: "missing_" <> _} -> reraise e, __STACKTRACE__
        _ -> reraise %{e | message: "invalid_#{key}", info: e.message, type: type}, __STACKTRACE__
      end
    e ->
      raise Igor.DecodeError, message: "invalid_#{key}", info: Map.get(e, :message), type: type
  end

  @spec pack_field(json(), String.t(), term(), type()) :: json()
  def pack_field(json_object, _key, nil, _type), do: json_object
  def pack_field(json_object, key, value, type), do: Map.put(json_object, key, pack_value(value, type))

  @spec parse_value(json(), type()) :: term()
  def parse_value(value, :boolean) when is_boolean(value), do: value
  # def parse_value(value, :sbyte) when is_integer(value) and value >= -128 and value <= 127, do: value
  # def parse_value(value, :byte) when is_integer(value) and value >= 0 and value <= 255, do: value
  # def parse_value(value, :short) when is_integer(value) and value >= -32768 and value <= 32767, do: value
  # def parse_value(value, :ushort) when is_integer(value) and value >= 0 and value <= 65535, do: value
  # def parse_value(value, :int) when is_integer(value) and value >= -2147483648 and value <= 2147483647, do: value
  # def parse_value(value, :uint) when is_integer(value) and value >= 0 and value <= 4294967295, do: value
  # def parse_value(value, :long) when is_integer(value) and value >= -9223372036854775808 and value <= 9223372036854775807, do: value
  # def parse_value(value, :ulong) when is_integer(value) and value >= 0 and value <= 18446744073709551615, do: value
  def parse_value(value, :sbyte) when is_integer(value), do: value |> check_min_max(-128, 127)
  def parse_value(value, :byte) when is_integer(value), do: value |> check_min_max(0, 255)
  def parse_value(value, :short) when is_integer(value), do: value |> check_min_max(-32768, 32767)
  def parse_value(value, :ushort) when is_integer(value), do: value |> check_min_max(0, 65535)
  def parse_value(value, :int) when is_integer(value), do: value |> check_min_max(-2147483648, 2147483647)
  def parse_value(value, :uint) when is_integer(value), do: value |> check_min_max(0, 4294967295)
  def parse_value(value, :long) when is_integer(value), do: value |> check_min_max(-9223372036854775808, 9223372036854775807)
  def parse_value(value, :ulong) when is_integer(value), do: value |> check_min_max(0, 18446744073709551615)
  def parse_value(value, :float) when is_number(value), do: value / 1
  def parse_value(value, :double) when is_number(value), do: value / 1
  def parse_value(value, :binary) when is_binary(value), do: Base.decode64(value)
  def parse_value(value, :string) when is_binary(value), do: value
  def parse_value(value, :atom) when is_binary(value), do: String.to_atom(value)
  def parse_value(value, :json), do: value
  def parse_value(list, {:list, type}) when is_list(list), do: for value <- list, do: parse_value(value, type)
  def parse_value(json_object, {:map, key_type, value_type}), do: for {key, value} <- json_object, into: %{}, do: {parse_key(key, key_type), parse_value(value, value_type)}
  def parse_value(nil, {:option, _}), do: nil
  def parse_value(value, {:option, type}), do: parse_value(value, type)
  def parse_value(value, {:custom, module}), do: module.from_json!(value)
  def parse_value(value, {:custom, module, type_args}), do: module.from_json!(value, type_args)
  def parse_value(_, type), do: raise Igor.DecodeError, message: "invalid_conversion", info: type

  defp parse_key("true", :boolean), do: true
  defp parse_key("false", :boolean), do: false
  defp parse_key(value, :sbyte), do: String.to_integer(value) |> check_min_max(-128, 127)
  defp parse_key(value, :byte), do: String.to_integer(value) |> check_min_max(0, 255)
  defp parse_key(value, :short), do: String.to_integer(value) |> check_min_max(-32768, 32767)
  defp parse_key(value, :ushort), do: String.to_integer(value) |> check_min_max(0, 65535)
  defp parse_key(value, :int), do: String.to_integer(value) |> check_min_max(-2147483648, 2147483647)
  defp parse_key(value, :uint), do: String.to_integer(value) |> check_min_max(0, 4294967295)
  defp parse_key(value, :long), do: String.to_integer(value) |> check_min_max(-9223372036854775808, 9223372036854775807)
  defp parse_key(value, :ulong), do: String.to_integer(value) |> check_min_max(0, 18446744073709551615)
  defp parse_key(value, :float), do: string_to_float(value)
  defp parse_key(value, :double), do: string_to_float(value)
  defp parse_key(value, :binary), do: value
  defp parse_key(value, :string), do: value
  defp parse_key(value, :atom), do: String.to_atom(value)
  defp parse_key(value, {:custom, module}), do: module.from_json!(value)
  defp parse_key(value, {:custom, module, type_args}), do: module.from_json!(value, type_args)

  @spec pack_value(term(), type()) :: json()
  def pack_value(value, :boolean) when is_boolean(value), do: value
  # def pack_value(value, :sbyte) when is_integer(value) and value >= -128 and value <= 127, do: value
  # def pack_value(value, :byte) when is_integer(value) and value >= 0 and value <= 255, do: value
  # def pack_value(value, :short) when is_integer(value) and value >= -32768 and value <= 32767, do: value
  # def pack_value(value, :ushort) when is_integer(value) and value >= 0 and value <= 65535, do: value
  # def pack_value(value, :int) when is_integer(value) and value >= -2147483648 and value <= 2147483647, do: value
  # def pack_value(value, :uint) when is_integer(value) and value >= 0 and value <= 4294967295, do: value
  # def pack_value(value, :long) when is_integer(value) and value >= -9223372036854775808 and value <= 9223372036854775807, do: value
  # def pack_value(value, :ulong) when is_integer(value) and value >= 0 and value <= 18446744073709551615, do: value
  def pack_value(value, :sbyte) when is_integer(value), do: value |> check_min_max(-128, 127)
  def pack_value(value, :byte) when is_integer(value), do: value |> check_min_max(0, 255)
  def pack_value(value, :short) when is_integer(value), do: value |> check_min_max(-32768, 32767)
  def pack_value(value, :ushort) when is_integer(value), do: value |> check_min_max(0, 65535)
  def pack_value(value, :int) when is_integer(value), do: value |> check_min_max(-2147483648, 2147483647)
  def pack_value(value, :uint) when is_integer(value), do: value |> check_min_max(0, 4294967295)
  def pack_value(value, :long) when is_integer(value), do: value |> check_min_max(-9223372036854775808, 9223372036854775807)
  def pack_value(value, :ulong) when is_integer(value), do: value |> check_min_max(0, 18446744073709551615)
  def pack_value(value, :float) when is_number(value), do: value
  def pack_value(value, :double) when is_number(value), do: value
  def pack_value(value, :binary) when is_binary(value), do: Base.encode64(value)
  def pack_value(value, :string) when is_binary(value), do: value
  def pack_value(value, :atom) when is_atom(value), do: Atom.to_string(value)
  def pack_value(value, :json), do: value
  def pack_value(list, {:list, type}) when is_list(list), do: for value <- list, do: pack_value(value, type)
  def pack_value(dict, {:map, key_type, value_type}) when is_map(dict), do: for {key, value} <- dict, into: %{}, do: {pack_key(key, key_type), pack_value(value, value_type)}
  def pack_value(nil, {:option, _}), do: nil
  def pack_value(value, {:option, type}), do: pack_value(value, type)
  def pack_value(value, {:custom, module}), do: module.to_json!(value)
  def pack_value(value, {:custom, module, type_args}), do: module.to_json!(value, type_args)

  defp pack_key(true, :boolean), do: "true"
  defp pack_key(false, :boolean), do: "false"
  # defp pack_key(value, :sbyte) when is_integer(value) and value >= -128 and value <= 127, do: Integer.to_string(value)
  # defp pack_key(value, :byte) when is_integer(value) and value >= 0 and value <= 255, do: Integer.to_string(value)
  # defp pack_key(value, :short) when is_integer(value) and value >= -32768 and value <= 32767, do: Integer.to_string(value)
  # defp pack_key(value, :ushort) when is_integer(value) and value >= 0 and value <= 65535, do: Integer.to_string(value)
  # defp pack_key(value, :int) when is_integer(value) and value >= -2147483648 and value <= 2147483647, do: Integer.to_string(value)
  # defp pack_key(value, :uint) when is_integer(value) and value >= 0 and value <= 4294967295, do: Integer.to_string(value)
  # defp pack_key(value, :long) when is_integer(value) and value >= -9223372036854775808 and value <= 9223372036854775807, do: Integer.to_string(value)
  # defp pack_key(value, :ulong) when is_integer(value) and value >= 0 and value <= 18446744073709551615, do: Integer.to_string(value)
  defp pack_key(value, :sbyte) when is_integer(value), do: Integer.to_string(value |> check_min_max(-128, 127))
  defp pack_key(value, :byte) when is_integer(value), do: Integer.to_string(value |> check_min_max(0, 255))
  defp pack_key(value, :short) when is_integer(value), do: Integer.to_string(value |> check_min_max(-32768, 32767))
  defp pack_key(value, :ushort) when is_integer(value), do: Integer.to_string(value |> check_min_max(0, 65535))
  defp pack_key(value, :int) when is_integer(value), do: Integer.to_string(value |> check_min_max(-2147483648, 2147483647))
  defp pack_key(value, :uint) when is_integer(value), do: Integer.to_string(value |> check_min_max(0, 4294967295))
  defp pack_key(value, :long) when is_integer(value), do: Integer.to_string(value |> check_min_max(-9223372036854775808, 9223372036854775807))
  defp pack_key(value, :ulong) when is_integer(value), do: Integer.to_string(value |> check_min_max(0, 18446744073709551615))
  defp pack_key(value, :float) when is_number(value), do: Float.to_string(value / 1)
  defp pack_key(value, :double) when is_number(value), do: Float.to_string(value / 1)
  defp pack_key(value, :binary) when is_binary(value), do: value
  defp pack_key(value, :string) when is_binary(value), do: value
  defp pack_key(value, :atom) when is_atom(value), do: Atom.to_string(value)
  defp pack_key(value, {:custom, module}), do: module.to_json!(value)
  defp pack_key(value, {:custom, module, type_args}), do: module.to_json!(value, type_args)

  defp string_to_float(string) do
    {value, ""} = Float.parse(string)
    value
  end

  defp check_min_max(value, min, max)
    when is_integer(value) and is_integer(min) and is_integer(max)
    and value >= min and value <= max
  do
    value
  end
  defp check_min_max(value, min, max)
    when is_integer(value) and is_integer(min) and is_integer(max)
  do
    raise Igor.DecodeError, message: "invalid_range", info: "not in range #{min}..#{max}"
  end

end
