defmodule VirtualCrypto.Metadata.Validator do
  def slice_string(str, max) do
    if count_codepoints(str) > max do
      "#{String.slice(str, 0..max)}..."
    else
      str
    end
  end

  defp count_codepoints(str) do
    str |> String.codepoints() |> length()
  end

  def validate_metadata_key(key) do
    if count_codepoints(key) > 40 do
      {:error, "too large(max: 40) metadata key(#{key |> String.slice(0..40)}...)"}
    else
      :ok
    end
  end

  def validate_metadata_value(key, value) do
    if value do
      if count_codepoints(value) > 500 do
        {:error,
         "too large metadata value(max: 500) at #{slice_string(key, 40)}(#{slice_string(value, 500)})"}
      else
        :ok
      end
    else
      :ok
    end
  end

  def validate_metadata_entry({key, value}) do
    case validate_metadata_key(key) do
      :ok -> []
      {:error, x} -> [x]
    end ++
      case validate_metadata_value(key, value) do
        :ok -> []
        {:error, x} -> [x]
      end
  end

  def validate_metadata(metadata_entries, number_of_processed_entires \\ 0, errors \\ [])

  def validate_metadata(m, number_of_processed_entires, errors) when is_map(m) do
    validate_metadata(Enum.to_list(m), number_of_processed_entires, errors)
  end

  def validate_metadata([], number_of_processed_entires, errors) do
    if number_of_processed_entires > 50 do
      ["too many entries in metadata(max: 50)" | errors]
    else
      errors
    end
  end

  def validate_metadata(
        [{_key, nil} = entry | metadata_entries],
        number_of_processed_entires,
        errors
      ) do
    validate_metadata(
      metadata_entries,
      number_of_processed_entires,
      errors ++ validate_metadata_entry(entry)
    )
  end

  def validate_metadata(
        [{_key, _value} = entry | metadata_entries],
        number_of_processed_entires,
        errors
      ) do
    validate_metadata(
      metadata_entries,
      number_of_processed_entires + 1,
      errors ++ validate_metadata_entry(entry)
    )
  end
end
