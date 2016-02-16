defmodule HTMLBuilder do
  alias HTMLBuilder.Encoder

  @spec encode(Encoder.t, Keyword.t) :: {:ok, iodata} | {:ok, String.t}
    | {:error, {:invalid, any}}
  def encode(value, options \\ []) do
    {:ok, encode!(value, options)}
  rescue
    exception in [Poison.EncodeError] ->
      {:error, {:invalid, exception.value}}
  end

  @spec encode_to_iodata(Encoder.t, Keyword.t) :: {:ok, iodata}
    | {:error, {:invalid, any}}
  def encode_to_iodata(value, options \\ []) do
    encode(value, [iodata: true] ++ options)
  end

  @spec encode!(Encoder.t, Keyword.t) :: iodata | no_return
  def encode!(value, options \\ []) do
    options = Enum.into(options, %{})
    iodata = Encoder.encode(value, options)
    unless options[:iodata] do
      iodata |> IO.iodata_to_binary
    else
      iodata
    end
  end

  @spec encode_to_iodata!(Encoder.t, Keyword.t) :: iodata | no_return
  def encode_to_iodata!(value, options \\ []) do
    encode!(value, [iodata: true] ++ options)
  end
end
