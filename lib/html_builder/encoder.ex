defprotocol HTMLBuilder.Encoder do
  def encode(value, options)
end

defmodule HTMLBuilder.Pretty do
  defmacro __using__(_) do
    quote do
      @default_indent 2
      @default_offset 0

      @compile {:inline, pretty: 1, indent: 1, offset: 1, offset: 2, spaces: 1}

      defp newline(%{pretty: true}), do: "\n"
      defp newline(_), do: []

      defp indentation(%{pretty: true} = options) do
        (indent(options) * offset(options)) |> spaces()
      end
      defp indentation(_) do
        []
      end

      def pretty(options) do
        !!Map.get(options, :pretty)
      end

      def indent(options) do
        Map.get(options, :indent, @default_indent)
      end

      def offset(options) do
        Map.get(options, :offset, @default_offset)
      end

      def offset(options, value) when value > 0 do
        Map.put(options, :offset, value)
      end
      def offset(options, _) do
        Map.put(options, :offset, 0)
      end

      defp inc_offset(options) do
        value = offset(options)
        offset(options, value + 1)
      end

      defp dec_offset(options) do
        value = offset(options)
        offset(options, value - 1)
      end

      def spaces(count) do
        :binary.copy(" ", count)
      end
    end
  end
end

defimpl HTMLBuilder.Encoder, for: Atom do
  def encode(nil, _),          do: ""
  def encode(:undefined, _),   do: ""

  def encode(atom, options) do
    atom
    |> Atom.to_string()
    |> HTMLBuilder.Encoder.BitString.encode(options)
  end
end

defimpl HTMLBuilder.Encoder, for: BitString do
  def encode(string, _options) do
    string
    |> HTMLBuilder.Utils.grapheme_stream()
    |> Enum.map(&HTMLBuilder.Utils.escape_character/1)
  end
end


defimpl HTMLBuilder.Encoder, for: Integer do
  def encode(integer, _options) do
    Integer.to_string(integer)
  end
end

defimpl HTMLBuilder.Encoder, for: Float do
  def encode(float, _options) do
    :io_lib_format.fwrite_g(float)
  end
end

defimpl HTMLBuilder.Encoder, for: List do
  use HTMLBuilder.Pretty

  def encode(list, options) do
    [for item <- list do
      [newline(options),
       indentation(options),
       HTMLBuilder.Encoder.encode(item, inc_offset(options))]
     end,
     newline(options),
     indentation(dec_offset(options))]
  end
end

defimpl HTMLBuilder.Encoder, for: Tuple do
  use HTMLBuilder.Pretty

  def encode({:__safe__, string}, _options) do
    string
  end
  def encode({:__comment__, comment}, options) do
    ["<!-- ", HTMLBuilder.Encoder.encode(comment, options), " -->"]
  end
  def encode({el, body}, options) when el in [:html, "html", 'html'] do
    ["<!DOCTYPE html>", newline(%{pretty: true}),
     "<html>",
     HTMLBuilder.Encoder.encode(body, options),
     "</html>", newline(options)]
  end
  def encode({el, attributes, body}, options) when el in [:html, "html", 'html'] do
    ["<!DOCTYPE html>", newline(%{pretty: true}),
     "<html", encode_attributes(attributes), ?>,
     HTMLBuilder.Encoder.encode(body, options),
     "</html>", newline(options)]
  end

  void_elements = ~W(
    area
    base
    br
    col
    embed
    hr
    img
    input
    keygen
    link
    meta
    param
    source
    track
    wbr
  )a

  for el <- void_elements do
    el_s = Atom.to_string(el)
    def encode({unquote(el)}, _options) do
      [?<, unquote(el_s), ?>]
    end
    def encode({unquote(el_s)}, _options) do
      [?<, unquote(el_s), ?>]
    end
    def encode({unquote(el), attributes}, _options) do
      [?<, unquote(el_s), encode_attributes(attributes), ?>]
    end
    def encode({unquote(el_s), attributes}, _options) do
      [?<, unquote(el_s), encode_attributes(attributes), ?>]
    end
    def encode({unquote(el_s), attributes, contents}, _options) when contents in [nil, []] do
      [?<, unquote(el_s), encode_attributes(attributes), ?>]
    end
    def encode({unquote(el), _, _}, _options) do
      throw :void_element
    end
    def encode({unquote(el_s), _, _}, _options) do
      throw :void_element
    end
  end

  def encode({el}, options) when is_atom(el) do
    encode({Atom.to_string(el)}, options)
  end
  def encode({el}, _options) do
    [?<, el, ?>, "</", el, ?>]
  end
  def encode({el, attributes}, options) when is_atom(el) do
    encode({Atom.to_string(el), attributes}, options)
  end
  def encode({el, attributes}, _options) do
    [?<, el, encode_attributes(attributes), ?>,
     "</", el, ?>]
  end
  def encode({el, attributes, contents}, options) when is_atom(el) do
    encode({Atom.to_string(el), attributes, contents}, options)
  end
  def encode({el, attributes, contents}, options) do
    [?<, el, encode_attributes(attributes), ?>,
     HTMLBuilder.Encoder.encode(contents, options),
     "</", el, ?>]
  end

  defp encode_attributes(attributes) when is_nil(attributes) or map_size(attributes) == 0 or length(attributes) == 0 do
    []
  end
  defp encode_attributes(attributes) do
    Enum.map(attributes, fn
      {_, value} when is_nil(value) or value == false ->
        []
      {key, true} ->
        [" ", to_string(key)]
      {key, ""} ->
        [" ", to_string(key), "=\"\""]
      {key, value} ->
        [" ", to_string(key), ?=, encode_attribute_value(value)]
    end)
  end

  defp encode_attribute_value(value) when is_binary(value) do
    graphemes = value
    |> HTMLBuilder.Utils.grapheme_stream()
    |> Enum.map(&HTMLBuilder.Utils.escape_character/1)

    must_quote = graphemes |> Enum.any?(&check_quote/1)

    if must_quote do
      [?", graphemes, ?"]
    else
      graphemes
    end
  end
  defp encode_attribute_value(value) do
    value |> to_string |> encode_attribute_value
  end

  defp check_quote(character) when character in [" ", "\t", "\r", "\n", "\f", "\0", "\"", "'", "=", ">", "<", "`"], do: true
  defp check_quote(character), do: false
end
