module Index exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


main =
  div [] [
    section [class "hero"] [
      div [class "hero-body"] [
        div [class "container"] [
          div [class "is-size-1 title", style "margin-top" "80px"] [text "コミュニティのための画期的な経済システム。"]
        , div [class "is-size-4 subtitle"] [text "記念品や対価、報酬などに使えるあなたのサーバー固有の通貨を作成しましょう。"]
        , large_button "/invite" "Botを招待する"
        , large_button "/document" "使い方を見る"
        ]
      ]
    ]
  ]


large_button: String -> String -> Html msg
large_button url text_ =
    a [href url, class "button is-info mx-2 is-large px-6"] [text text_]