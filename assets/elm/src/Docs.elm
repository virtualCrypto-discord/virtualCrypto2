module Docs exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown exposing (defaultOptions)

type alias Model = String
type Msg = Nothing


main : Program Model Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


init: Model -> ( Model, Cmd Msg )
init data = (data, Cmd.none)

update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
  ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

view: Model -> Html msg
view model =
  div [class "columns"] [
    div [class "column is-2"] []
  , div [class "column is-6"] [
      div [class "content"] [htmlData model]
    ]
  ]

htmlData: String -> Html msg
htmlData model = Markdown.toHtmlWith
  { defaultOptions
      | sanitize = False
  }
  []
  model
