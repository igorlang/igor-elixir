defmodule Igor.Http do

  defmodule BadRequestError do

    defexception message: "Bad Request"

  end

  defmodule HttpError do

    defexception [:status_code, :body, :headers]

    def message(exception), do: "HTTP error #{exception.status_code}"

  end

  def compose_query(query_parts) do
    query_parts
      |> Enum.flat_map(&format_query/1)
      |> compose_query_string
  end

  defp compose_query_string(parts) do
    for {name, value} <- parts do [name, "=", value] end |> Enum.join("&")
  end

  defp format_query({name, value}), do: [{name, value}]
  defp format_query({name, value, type}), do: format_query(name, value, type)
  defp format_query({_name, value, _format, default}) when value === default, do: []
  defp format_query({name, value, type, _default}), do: format_query(name, value, type)

  defp format_query(_name, nil, _type), do: []
  defp format_query(name, value, {:option, type}), do: format_query(name, value, type)
  defp format_query(name, value, {:list, item_type}) when is_list(value), do: for item <- value, do: {name, format_value(item, item_type)}
  defp format_query(name, value, type), do: [ {name, format_value(value, type)} ]

  def parse_query(param, qs, {:option, type}) do
    parse_query(param, qs, type, nil)
  end
  def parse_query(param, qs, type) do
    try do
      case parse_query_opt(param, qs, type) do
        nil -> raise BadRequestError, message: "Missing query parameter #{param}"
        value -> value
      end
    rescue
      bad_request in BadRequest -> reraise bad_request, __STACKTRACE__
      _ -> raise BadRequestError, message: "Malformed query parameter #{param}"
    end
  end

  def parse_query(param, qs, type, default) do
    try do
      case parse_query_opt(param, qs, type) do
        nil -> default
        value -> value
      end
    rescue
      _ -> raise BadRequestError, message: "Malformed query parameter #{param}"
    end
  end

  defp parse_query_opt(param, qs, {:custom_query, fun}) do
    fun.(param, qs)
  end
  defp parse_query_opt(param, qs, {:option, type}) do
    parse_query_opt(param, qs, type)
  end
  defp parse_query_opt(param, qs, type) do
    case Map.get(qs, param) do
        nil -> nil
        string -> parse_value(string, type)
    end
  end

  def parse_header(header, values, {:option, type}) do
    parse_header(header, values, type, nil)
  end
  def parse_header(header, [], _Type) do
    raise BadRequestError, message: "missing_header #{header}"
  end
  def parse_header(_header, [value| _], type) when is_binary(value) do
    parse_value(value, type)
  end

  def parse_header(_header, [], _type, default), do: default
  def parse_header(header, values, type, _default), do: parse_header(header, values, type)

  def parse_path(param, path_params, type) do
    case Map.get(path_params, param) do
      nil -> raise BadRequestError, message: "missing path param #{param}"
      value ->
        try do
          parse_value(value, type)
        rescue
          _ -> raise BadRequestError, message: "invalid path param #{param}"
        end
    end
  end

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
  def parse_value(value, {:list, separator, item_type}), do: for item <- String.split(value, separator, global: true), do: parse_value(item, item_type)
  def parse_value(value, {:custom, module}), do: module.from_string!(value)
  def parse_value(value, {:json, json_tag}), do: value |> Igor.Json.decode! |> Igor.Json.parse_value(json_tag)

  def format_value(true, :boolean), do: "true"
  def format_value(false, :boolean), do: "false"
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
  def format_value(value, :binary) when is_binary(value), do: URI.encode(value)
  def format_value(value, :string) when is_binary(value), do: URI.encode(value)
  def format_value(value, :atom) when is_atom(value), do: URI.encode(Atom.to_string(value))
  def format_value(value, {:list, separator, item_type}) when is_list(value), do: Enum.join(for item <- value do format_value(item, item_type) end, separator)
  def format_value(value, {:custom, module}), do: module.to_string!(value)
  def format_value(value, {:json, json_tag}), do: value |> Igor.Json.pack_value(json_tag) |> Igor.Json.encode! |> URI.encode

  defp string_to_float(string) do
    {value, ""} = Float.parse(string)
    value
  end

end
