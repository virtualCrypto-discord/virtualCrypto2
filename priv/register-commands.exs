defmodule Command do
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
      "description" => "発行枠から通貨を発行します。管理者権限が必要です。amountを省略した場合は全額が指定されたuserに発行されます。",
      "options" => [
        %{
          "name" => "user",
          "description" => "発行先のユーザーです。",
          "type" => 6,
          "required" => true
        },
        %{
          "name" => "amount",
          "description" => "発行する通貨の量です。",
          "type" => 4,
          "required" => false
        }
      ],
      "dm_permission" => false,
      "default_member_permissions" => "0"
    }
  end

  def pay do
    %{
      "name" => "pay",
      "description" => "指定したユーザーに通貨を指定した分だけ送信します。",
      "options" => [
        %{
          "name" => "unit",
          "description" => "送信したい通貨の単位です。",
          "type" => 3,
          "required" => true,
          "autocomplete"=> true
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
      "options" => [
        %{
          "name" => "name",
          "description" => "検索したい通貨の通貨名です。",
          "type" => 3,
          "required" => false,
          "autocomplete"=> true
        },
        %{
          "name" => "unit",
          "description" => "検索したい通貨の単位です。",
          "type" => 3,
          "required" => false,
          "autocomplete"=> true
        }
      ]
    }
  end

  def create do
    %{
      "name" => "create",
      "description" => "新しい通貨を作成します",
      "options" => [
        %{
          "name" => "name",
          "description" => "新しい通貨の通貨名です。2~32文字までの英数字です。",
          "type" => 3,
          "required" => true
        },
        %{
          "name" => "unit",
          "description" => "新しい通貨の単位です。1~10文字の英子文字です。",
          "type" => 3,
          "required" => true
        },
        %{
          "name" => "amount",
          "description" => "通貨の初期発行枚数です。あなたの所持金となります。",
          "type" => 4,
          "required" => true
        }
      ],
      "dm_permission" => false,
      "default_member_permissions" => "0"
    }
  end

  def delete do
    %{
      "name" => "delete",
      "description" => "通貨を削除します。削除は、作成後72時間の間のみ可能です",
      "dm_permission" => false,
      "default_member_permissions" => "0"
    }
  end

  def bal do
    %{
      "name" => "bal",
      "description" => "自分の所持通貨を確認します。"
    }
  end

  defp options_for_listing(user_desc) do
    [
      %{
        "name" => "pending",
        "description" => "未処理の請求を表示します。",
        "type" => 5
      },
      %{
        "name" => "approved",
        "description" => "承諾済みの請求を表示します。",
        "type" => 5
      },
      %{
        "name" => "denied",
        "description" => "拒否済みの請求を表示します。",
        "type" => 5
      },
      %{
        "name" => "canceled",
        "description" => "キャンセル済みの請求を表示します。",
        "type" => 5
      },
      %{
        "name" => "user",
        "description" => user_desc,
        "type" => 6
      }
    ]
  end

  def claim do
    %{
      "name" => "claim",
      "description" => "請求に関するコマンドです。",
      "options" => [
        %{
          "name" => "list",
          "description" => "請求の一覧を表示します。",
          "type" => 1,
          "options" => options_for_listing("ユーザーからの請求及びユーザーへの請求を表示します。")
        },
        %{
          "name" => "received",
          "description" => "受け取った請求の一覧を表示します。",
          "type" => 1,
          "options" => options_for_listing("請求元を指定します。")
        },
        %{
          "name" => "sent",
          "description" => "送信した請求の一覧を表示します。",
          "type" => 1,
          "options" => options_for_listing("請求先を指定します。")
        },
        %{
          "name" => "make",
          "description" => "請求を作成します。",
          "type" => 1,
          "options" => [
            %{
              "name" => "user",
              "description" => "請求先のユーザーです。",
              "type" => 6,
              "required" => true
            },
            %{
              "name" => "unit",
              "description" => "請求する通貨の単位です。",
              "type" => 3,
              "required" => true,
              "autocomplete"=> true
            },
            %{
              "name" => "amount",
              "description" => "請求する通貨の枚数です。",
              "type" => 4,
              "required" => true
            }
          ]
        },
        %{
          "name" => "approve",
          "description" => "請求を承諾し支払います。",
          "type" => 1,
          "options" => [
            %{
              "name" => "id",
              "description" => "請求の番号です。",
              "type" => 4,
              "required" => true,
              "autocomplete" => true
            }
          ]
        },
        %{
          "name" => "deny",
          "description" => "請求を拒否します。",
          "type" => 1,
          "options" => [
            %{
              "name" => "id",
              "description" => "請求の番号です。",
              "type" => 4,
              "required" => true,
              "autocomplete" => true
            }
          ]
        },
        %{
          "name" => "cancel",
          "description" => "自分が送った請求をキャンセルします。",
          "type" => 1,
          "options" => [
            %{
              "name" => "id",
              "description" => "請求の番号です。",
              "type" => 4,
              "required" => true,
              "autocomplete" => true
            }
          ]
        },
        %{
          "name" => "show",
          "description" => "請求を表示します。",
          "type" => 1,
          "options" => [
            %{
              "name" => "id",
              "description" => "請求の番号です。",
              "type" => 4,
              "required" => true,
              "autocomplete" => true
            }
          ]
        }
      ]
    }
  end

  def put(url) do
    HTTPoison.start()

    headers = [
      {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
      {"Content-Type", "application/json"}
    ]

    commands = [help(), invite(), give(), pay(), info(), create(), delete(), bal(), claim()]

    {:ok,r} = HTTPoison.put(url, Jason.encode!(commands), headers)
    IO.puts(r.status_code)
  end
end

url = case System.argv() do
  [] -> "https://discord.com/api/v10/applications/"<>Application.get_env(:virtualCrypto, :client_id)<>"/commands"
  [guild] -> "https://discord.com/api/v10/applications/"<>Application.get_env(:virtualCrypto, :client_id)<>"/guilds/"<>guild<>"/commands"
end
Command.put(url)
