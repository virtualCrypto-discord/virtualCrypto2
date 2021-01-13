defmodule Mix.Tasks.Docs.Parse do
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")

    {:ok,  files} = File.ls "./docs"
    files
    |> Enum.filter(fn file -> String.ends_with?(file, ".md") end)
    |> Enum.map(fn file -> VirtualCrypto.MarkdownParser.parse(file) end)

  end
end