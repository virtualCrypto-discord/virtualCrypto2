defmodule VirtualCryptoWeb.JsonUtil do
  defp is_safe_integer(v) do
  end

  def to_integer(v) when is_binary(v) do
    String.to_integer(v)
  end

  def to_integer(v) when is_integer(v) do
    v
  end

  def parse_to_integer(v) when is_binary(v) do
    case Integer.parse(v) do
      {v, ""} -> v
      _ -> :error
    end
  end
end
