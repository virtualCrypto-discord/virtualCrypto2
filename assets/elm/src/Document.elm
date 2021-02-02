module Document exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


main =
  div [] [
    div [class "hero mt-5 is-medium is-info"] [
      div [class "hero-body"] [
        div [class "container"] [
          h1 [class "title"] [text "ドキュメント"]
        , h2 [class "subtitle"] [text "コマンドやAPIの仕様"]
        ]
      ]
    ]
  , div [class "tile is-ancestor mt-5 notification is-white"] [
      div [class "tile is-8", style "margin" "0 auto"] [
        documentButton "VirtualCrypto" "VirtualCryptoの仕組みについて" "/document/about"
      , documentButton "コマンド" "VirtualCryptoのDiscord Botで使用できるコマンドについて" "/document/commands"
      , documentButton "API" "VirtualCryptoのAPIの使用方法について" "/document/api"
      ]
    ]
  ]


documentButton: String -> String -> String -> Html msg
documentButton title desc url =
    div [class "tile is-parent"] [
        article [class "tile is-child notification is-primary box"] [
        p [class "title"] [a [style "text-decoration" "none", href url] [text title]]
        , p [class "subtitle"] [a [style "text-decoration" "none", href url] [text desc]]
        , div [class "content"] []
        ]
    ]
