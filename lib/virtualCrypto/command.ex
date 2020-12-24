defmodule VirtualCrypto.Command do
  @moduledoc """
  """

  def help do
    %{
      "name" => "help",
      "description" => "ヘルプを表示します。"
    }
  end

  def invite do
    %{
      "name" => "invite",
      "description" => "Botの招待URLを表示します。"
    }
  end

  def give do
    %{
      "name" => "give",
      "description" => "未配布分の通貨を送信します。管理者権限が必要です。",
      "options": [
        %{
          "name" => "user",
          "description" => "送信先のユーザーです。",
          "type" => 6,
          "required" => true
        },
        %{
          "name" => "amount",
          "description" => "送信する通貨の量です。",
          "type" => 4,
          "required" => true,
          "choices" => [
            %{"name" => "1", "value" => 1},
            %{"name" => "10", "value" => 10},
            %{"name" => "100", "value" => 100}
          ]
        }
      ]
    }
  end

  def pay do
    %{
      "name" => "pay",
      "description" => "指定したユーザーに通貨を指定した分だけ送信します。",
      "options": [
        %{
          "name" => "unit",
          "description" => "検索したい通貨の単位です。",
          "type" => 3,
          "required" => true
        },
        %{
          "name" => "user",
          "description" => "送信先のユーザーです。",
          "type" => 6,
          "required" => true
        },
        %{
          "name" => "amount",
          "description" => "送信する通貨の量です。",
          "type" => 4,
          "required" => true
        }
      ]
    }
  end

  def info do
    %{
      "name" => "info",
      "description" => "通貨の情報を表示します。通貨名または単位がない場合はそのサーバーの通貨を表示します。",
      "options": [
        %{
          "name" => "name",
          "description" => "検索したい通貨の通貨名です。",
          "type" => 3,
          "required" => false
        },
        %{
          "name" => "unit",
          "description" => "検索したい通貨の単位です。",
          "type" => 3,
          "required" => false
        }
      ]
    }
  end

  def create do
    %{
      "name" => "create",
      "description" => "新しい通貨を作成します",
      "options": [
        %{
          "name" => "name",
          "description" => "新しい通貨の通貨名です。",
          "type" => 3,
          "required" => true
        },
        %{
          "name" => "unit",
          "description" => "新しい通貨の単位です。",
          "type" => 3,
          "required" => true
        }
      ]
    }
  end

  def bal do
    %{
      "name" => "bal",
      "description" => "自分の所持通貨を確認します。"
    }
  end

  def post_all do
    HTTPoison.start
    headers = [
      {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
      {"Content-Type", "application/json"}]
    url = Application.get_env(:virtualCrypto, :command_post_url)
    commands = [give(), pay(), info(), create(), bal()]
    commands |> Enum.each(fn (command) ->
      r = HTTPoison.post(url, (Jason.encode!(command)), headers)
      IO.inspect r
    end)
  end
end
