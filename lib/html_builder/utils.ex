defmodule HTMLBuilder.Utils do
  def grapheme_stream(binary) do
    Stream.unfold(binary, &String.next_grapheme/1)
  end

  def escape_character("'"), do: "&apos;"
  def escape_character("\""), do: "&quot;"
  def escape_character("&"), do: "&amp;"
  def escape_character("<"), do: "&lt;"
  def escape_character(">"), do: "&gt;"
  def escape_character(original), do: original
end
