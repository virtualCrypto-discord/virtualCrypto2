module Mypage.Applications exposing (..)
import Html exposing (..)
import Url.Builder exposing (absolute, string)
import Http
import Api
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
            { url = absolute [ "oauth2", "clients" ] [string "user" "@me"]
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
    case msg of
        InjectUserData user ->
            ( { model | userData = Just user }, getApplications model.accessToken)
        GotApplications result ->
            case result of
                Ok data ->
                    ( { model | applications = Just data }, Cmd.none)
                Err _ ->
                    ( model, Cmd.none)


view : Model -> Html Msg
view model =
    case model.applications of
        Just applications -> text "a"
        Maybe.Nothing -> text ""
