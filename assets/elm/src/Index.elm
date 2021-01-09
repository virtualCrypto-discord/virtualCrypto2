module Index exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


main =
  div [] [
    div [class "columns"] [
        div [class "column is-three-fifths"] [
          div [class "is-size-1 has-text-centered", style "margin-top" "80px"] [text "コミュニティのための画期的な経済システム。"]
          , div [class "is-size-4 has-text-centred"] [text "記念品や対価、報酬などに使えるあなたのサーバー固有の通貨を作成しましょう。"]
          , div [class "columns"] [
            div [class "column mt-5 has-text-centered"] [
              large_button "/invite" "Botを招待する"
              , large_button "/document" "使い方を見る"
            ]
          ]
        ]
        , div [class "column has-text-centered is-size-2"] [text "ここにロゴかなんか入れたかった人生だった"]
      ]
  ]


large_button: String -> String -> Html msg
large_button url text_ =
    a [href url, class "button is-info mx-2 is-large px-6"] [text text_]