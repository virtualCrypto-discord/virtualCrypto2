module Mypage.Applications exposing (..)
import Html exposing (..)
import Url.Builder exposing (absolute)
import Http
import Api
import Json.Decode exposing (field, Decoder, map2, map4, string, int, list)
import Types.User exposing (User)
import Types.Applications exposing (Applications, applicationsDecoder)


type alias Model =
    { applications : Maybe Applications
    , accessToken : String
    , userData : Maybe User
    }

getApplications : String -> Cmd Msg
getApplications token =
    Api.get
            { url = absolute [ "api", "v1", "users", "@me", "claims" ] []
            , expect = Http.expectJson GotApplications applicationsDecoder
            , token = token
            }


type Msg
    = InjectUserData User
    | GotApplications (Result Http.Error Applications)


init : String -> Maybe User -> ( Model, Cmd Msg )
init accessToken userData  =
    ( { accessToken = accessToken
      , userData = userData
      , applications = Maybe.Nothing
      }, Cmd.none)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    (model, Cmd.none)


view : Model -> Html Msg
view model =
    text ""
