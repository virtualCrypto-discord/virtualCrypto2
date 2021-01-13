defmodule VirtualCrypto.MarkdownParser do
  def parse(filename) do
    data = File.read! ~s/.\/docs\/#{filename}/
    {:ok, data2, _} = data |> EarmarkParser.as_ast

    data2
    |> set_id
    |> Earmark.Transform.transform
    |> write_parsed(filename)
  end

  def set_id(parsed) do
    parsed
    |> Enum.map(fn line ->
      case line do
        {"h1", attributes, text, children} -> {"div", (attributes ++ [{"id", text |> hd}, {"class", "is-size-3 has-text-weight-bold my-4"}]), text, children}
        {"h2", attributes, text, children} -> {"div", (attributes ++ [{"id", text |> hd}, {"class", "is-size-5 has-text-weight-bold my-4"}]), text, children}
        {"h3", attributes, text, children} -> {"div", (attributes ++ [{"id", text |> hd}, {"class", "has-text-weight-bold my-4"}]), text, children}
        others -> others
      end
    end)
  end

  def write_parsed(data, filename) do
    File.write(~s/.\/docs\/parsed\/#{filename}.html/, data)
  end
end
