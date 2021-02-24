module Mypage.Applications exposing (..)
import Html exposing (..)
import Url.Builder exposing (absolute)
import Http
import Api
import Json.Decode exposing (field, Decoder, map2, map4, string, int, list)


type alias Model =
    { applications : Maybe Applications
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


initCmd : String -> Cmd Msg
initCmd accessToken =
    getApplications accessToken


initModel : String -> Model
initModel _ =
    {applications = Maybe.Nothing}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    (model, Cmd.none)


view : Model -> Html Msg
view model =
    text ""
