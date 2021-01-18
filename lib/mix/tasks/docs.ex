defmodule Mix.Tasks.Docs.Parse do
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")

    VirtualCrypto.MarkdownParser.parse_all()
  end
end