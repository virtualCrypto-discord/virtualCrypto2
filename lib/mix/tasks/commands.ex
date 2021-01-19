defmodule Mix.Tasks.Commands.Post do
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")

    VirtualCrypto.Command.post_all()
  end
end
