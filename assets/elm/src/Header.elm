module Header exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


main =
  div [class "navbar mt-1"] [
    div [class "navbar-bland"] [
      span [class "navbar-item"] [
        a [href "/", class "has-text-black is-size-2"] [text "VirtualCrypto"]
      ]
    ]
    , div [class "navbar-end"] [
      header_buttons
    ]
  ]

header_buttons: Html msg
header_buttons =
  div [class "navbar-item"] [
          header_button "/invite" "Botの招待"
          , header_button "/support" "サポートサーバー"
          , header_button "/document" "使い方"
          , header_button "/login" "ログイン"
        ]


header_button: String -> String -> Html msg
header_button url text_ =
  a [href url, class "button is-info mx-3 is-light"] [text text_]