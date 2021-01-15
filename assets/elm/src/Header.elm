module Header exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)

type alias Flags = { is_login: Bool, name: String, id: String, avatar: String }

main : Program Flags Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model = { is_login: Bool, name: String, id: String, avatar: String }

type Msg = Nothing

init: Flags -> ( Model, Cmd Msg )
init data = (data, Cmd.none)

update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
  ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

view: Model -> Html msg
view model =
  div [class "navbar mt-1 mx-2"] [
    div [class "navbar-bland"] [
      span [class "navbar-item"] [
        a [href "/", class "has-text-black is-size-3"] [text "VirtualCrypto"]
      ]
    ]
    , div [class "navbar-end"] [
      header_buttons model
    ]
  ]

header_buttons: Model -> Html msg
header_buttons model =
  div [class "navbar-item"] [
          header_button "/invite" "Botの招待"
          , header_button "/support" "サポートサーバー"
          , header_button "/document" "ドキュメント"
          , if model.is_login
              then header_button "/me" "マイページ"
              else header_button "/login" "ログイン"
        ]


header_button: String -> String -> Html msg
header_button url text_ =
  a [href url, class "button is-info mx-3 is-light"] [text text_]