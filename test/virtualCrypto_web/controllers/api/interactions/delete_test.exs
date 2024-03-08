defmodule InteractionsControllerTest.Delete do
  alias VirtualCryptoWeb.Interaction.CustomId
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Helper.Common
  setup :setup_money

  test "delete command",
       %{conn: conn, unit: unit, user1: user, currency_guild: guild} do
    conn =
      execute_interaction(
        conn,
        execute_from_guild(
          %{
            name: "delete"
          },
          user,
          guild
        )
      )

    label = "確認のため、「delete #{unit}」と入力してください。"

    assert %{
             "type" => 9,
             "data" => %{
               "title" => "通貨の削除",
               "components" => [
                 %{
                   "type" => 1,
                   "components" => [
                     %{
                       "type" => 4,
                       "label" => ^label,
                       "style" => 1
                     }
                   ]
                 }
               ]
             }
           } = json_response(conn, 200)
  end

  test "confirm delete",
       %{conn: conn, unit: unit, user1: user, currency_guild: guild} do
    conn =
      execute_interaction(
        conn,
        modal_submit_from_guild(
          %{
            "custom_id" => CustomId.encode(0, CustomId.UI.Modal.confirm_currency_delete()),
            "components" => [
              %{
                "components" => [
                  %{
                    "value" => "delete #{unit}"
                  }
                ]
              }
            ]
          },
          user,
          guild
        )
      )

    assert %{
             "type" => 4,
             "data" => %{
               "flags" => 64,
               "content" => "通貨を削除しました。"
             }
           } = json_response(conn, 200)
  end

  test "out of term",
       %{conn: conn, user1: user, currency_guild: guild} do
    Process.put(:test_delete_now, NaiveDateTime.add(NaiveDateTime.utc_now(), 73 * 24 * 60 * 60))

    conn =
      execute_interaction(
        conn,
        execute_from_guild(
          %{
            name: "delete"
          },
          user,
          guild
        )
      )

    assert %{
             "data" => %{
               "allowed_mentions" => %{"parse" => []},
               "content" => "エラー: 作成から72時間以上経過しているため削除できません。",
               "flags" => 64
             },
             "type" => 4
           } == json_response(conn, 200)
  end
end
