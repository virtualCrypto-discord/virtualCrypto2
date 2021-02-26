module Mypage.Applications exposing (..)
import Html exposing (..)
import Url.Builder exposing (absolute, string)
import Http
import Api
import Types.User exposing (User)
import Types.Applications exposing (Application, Applications, applicationsDecoder)
import Html.Attributes exposing (..)
import Maybe exposing (withDefault)


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
        Just applications -> applicationsView model applications
        Maybe.Nothing -> loadingView

loadingView : Html msg
loadingView =
    div [ class "is-size-2 mx-5" ] [ text "Loading..." ]


applicationsView : Model -> Applications -> Html Msg
applicationsView model applications =
    div [class "column mt-5"]
        [ p [class "title"] [text "アプリケーション一覧"]
        , a [href "/", class "button is-medium mb-3 has-background-info has-text-white"] [text "新規アプリケーション"]
        , div [class "columns is-multiline"]
            (applications |> List.map applicationButton)
        ]

applicationButton : Application -> Html Msg
applicationButton application =
    div [class "card column is-2 mx-2 my-2"]
        [ div [class "card-image"]
            [ figure [class "is-4by3"]
                [ img [src <| withDefault "https://bulma.io/images/placeholders/1280x960.png" application.logo_uri] []
                ]
            ]
        , div [class "card-content"]
            [ div [class "media-content"]
                [ a [] [p [class "title"] [text <| withDefault "" application.client_name]]
                ]
            ]
        ]
