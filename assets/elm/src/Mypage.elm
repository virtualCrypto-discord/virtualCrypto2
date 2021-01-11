module Mypage exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode exposing (Decoder, map3, field, string)

type Status = Success
  | Failure


type alias UserData
  = { id : String, name: String, avatar: String}

type alias Model
  = { userData: UserData, userDataStatus: Status }

main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init: () -> ( Model, Cmd Msg )
init _ = ({ userData = { id = "", name = "", avatar = ""}, userDataStatus = Success}, getUserData)

type Msg = GotUserData (Result Http.Error UserData)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GotUserData result ->
      case result of
        Ok data -> ( { model | userData = data }, Cmd.none )
        Err _ -> ( { model | userDataStatus = Failure }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

view: Model -> Html msg
view model = div [] [
  text (model.userData.name ++ "さん！")
  ]

getUserData : Cmd Msg
getUserData =
  Http.get
    { url = "http://localhost/api/local/user/me"
    , expect = Http.expectJson GotUserData userDataDecoder
    }

userDataDecoder : Decoder UserData
userDataDecoder =
  map3 UserData
    (field "id" string)
    (field "name" string)
    (field "avatar" string)

