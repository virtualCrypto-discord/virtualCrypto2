module Document exposing (..)
import Browser
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
        div [class "tile is-parent"] [
          article [class "tile is-child notification is-primary box"] [
            p [class "title"] [a [style "text-decoration" "none", href "/document/commands"] [text "コマンド"]]
          , p [class "subtitle"] [a [style "text-decoration" "none", href "/document/commands"] [text "VirtualCryptoのDiscord Botで使用できるコマンドについて"]]
          , div [class "content"] []
          ]
        ]
      , div [class "tile is-parent"] [
          article [class "tile is-child notification is-primary box"] [
            p [class "title"] [a [style "text-decoration" "none"] [text "API(準備中)"]]
          , p [class "subtitle"] [a [style "text-decoration" "none"] [text "VirtualCryptoのAPIの使用方法について"]]
          , div [class "content"] []
          ]
        ]
      ]
    ]
  ]
