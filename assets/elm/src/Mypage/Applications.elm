module Mypage.Applications exposing (..)
import Html exposing (..)
import Url.Builder exposing (absolute)
import Http
import Api
import Json.Decode exposing (field, Decoder, map2, map4, string, int, list)
import Mypage.User exposing (User)


type alias Model =
    { applications : Maybe Applications
    , accessToken : String
    , userData : Maybe User
    }

type alias Application =
    { client_id : String
    , client_name : String
    , user_id : String
    , client_secret : String
    }

type alias Applications = List Application

applicationDecoder : Decoder Application
applicationDecoder =
    map4 Application
        (field "client_id" string)
        (field "client_name" string)
        (field "user_id" string)
        (field "client_secret" string)

applicationsDecoder : Decoder Applications
applicationsDecoder =
    applicationDecoder |> list

getApplications : String -> Cmd Msg
getApplications token =
    Api.get
            { url = absolute [ "api", "v1", "users", "@me", "claims" ] []
            , expect = Http.expectJson GotApplications applicationsDecoder
            , token = token
            }


type Msg
    = GotApplications (Result Http.Error Applications)


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
