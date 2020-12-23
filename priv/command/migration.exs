defmodule VirtualCrypto.Command.Migration do
  def give do
    %{
      "name" => "give",
      "description" => "未配布分の通貨を送信します。管理者権限が必要です。",
      "options": [
        %{
          "name" => "ユーザー",
          "description" => "送信先のユーザーです。",
          "type" => 6,
          "required" => true
        },
        %{
          "name" => "数量",
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
          "name" => "通貨の単位",
          "description" => "検索したい通貨の単位です。",
          "type" => 3,
          "required" => true
        },
        %{
          "name" => "ユーザー",
          "description" => "送信先のユーザーです。",
          "type" => 6,
          "required" => true
        },
        %{
          "name" => "数量",
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

  def info do
    %{
      "name" => "info",
      "description" => "通貨の情報を表示します。通貨名または単位がない場合はそのサーバーの通貨を表示します。",
      "options": [
        %{
          "name" => "通貨名",
          "description" => "検索したい通貨の通貨名です。",
          "type" => 3,
          "required" => false
        },
        %{
          "name" => "通貨の単位",
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
          "name" => "通貨名",
          "description" => "新しい通貨の通貨名です。",
          "type" => 3,
          "required" => true
        },
        %{
          "name" => "通貨の単位",
          "description" => "新しい通貨の単位です。",
          "type" => 3,
          "required" => true
        }
      ]
    }
  end

  def me do
    %{
      "name" => "me",
      "description" => "自分の所持通貨を確認します"
    }
  end

  def post command do

  end

  def post_all do
    commands = [give(), pay(), info(), create(), me()]
    commands |> Enum.each(fn command -> post command end)
  end
end