module Mypage.Error exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Url.Builder exposing (absolute)


type alias Model =
    Never


type alias Msg =
    Never


view : Html a
view =
    div [ class "column mt-5" ]
        [ text "問題が発生しました。"
        , a [ href (absolute [ "me" ] []) ] [ text "リロード" ]
        , text "してください。"
        , text "それでも問題が解決しない場合は"
        , a [ href (absolute [ "logout" ] []) ] [ text "ログアウト" ]
        , text "してやり直してください。"
        , br [] []
        , a [ href "https://discord.gg/Hgp5DpG" ] [ text "サポートサーバー" ]
        ]
