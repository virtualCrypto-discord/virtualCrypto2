module Mypage.Applications exposing (..)
import Html exposing (..)
import Url.Builder exposing (absolute, string)
import Http
import Browser.Navigation as Nav
import Api
import Types.User exposing (User)
import Types.Applications exposing (Application, Applications, applicationsDecoder, ClientRegistrationResponse, clientRegistrationResponseDecoder, clientRegistrationResponseEncoder)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Maybe exposing (withDefault)


type alias Model =
    { applications : Maybe Applications
    , accessToken : String
    , userData : Maybe User
    , isTogglePopup : Bool
    , newApplicationName : String
    }

getApplications : String -> Cmd Msg
getApplications token =
    Api.get
        { url = absolute [ "oauth2", "clients" ] [string "user" "@me"]
        , expect = Http.expectJson GotApplications applicationsDecoder
        , token = token
        }

createApplication : String -> String -> Cmd Msg
createApplication token name =
    Api.post
        { url = absolute [ "oauth2", "clients"] []
        , expect = Http.expectJson GotNewApplications clientRegistrationResponseDecoder
        , body = Http.jsonBody (clientRegistrationResponseEncoder name)
        , token = token
        }


type Msg
    = InjectUserData User
    | GotApplications (Result Http.Error Applications)
    | GotNewApplications (Result Http.Error ClientRegistrationResponse)
    | TogglePopup
    | InputName String
    | CreateNewApplication


init : String -> Maybe User -> ( Model, Cmd Msg )
init accessToken userData  =
    ( { accessToken = accessToken
      , userData = userData
      , applications = Maybe.Nothing
      , isTogglePopup = False
      , newApplicationName = ""
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
        TogglePopup ->
            ( { model | isTogglePopup = not model.isTogglePopup}, Cmd.none)
        InputName name ->
            ( {model | newApplicationName = name }, Cmd.none)
        CreateNewApplication ->
            ( model, createApplication model.accessToken model.newApplicationName )
        GotNewApplications result ->
            case result of
                Ok data ->
                    ( model, Nav.load ("/applications/" ++ data.client_id))
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
        , button [class "button is-medium mb-3 has-background-info has-text-white", onClick TogglePopup] [text "新規アプリケーション"]
        , div [class "columns is-multiline"]
            (applications |> List.map applicationButton)
        , if model.isTogglePopup then
            renderModal model
          else
            text ""
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
                [ a [href ("/applications/" ++ application.client_id)] [p [class "title"] [text <| withDefault "" application.client_name]]
                ]
            ]
        ]

renderModal : Model -> Html Msg
renderModal model =
    div [ class "modal is-active", attribute "aria-label" "新規アプリケーション作成" ]
        [ div [ class "modal-background", onClick TogglePopup ]
            []
        , div [ class "modal-card" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ]
                    [ text "新規アプリケーション作成" ]
                , button [ class "delete", onClick TogglePopup, attribute "aria-label" "close" ]
                    []
                ]
            , section [ class "modal-card-body" ]
                [ viewInput "text" "アプリケーション名" model.newApplicationName InputName
                ]
            , footer [ class "modal-card-foot" ]
                [ viewValidationButton model
                , button [ class "button", onClick TogglePopup, attribute "aria-label" "cancel" ] [ text "キャンセル" ]
                ]
            ]
        ]

viewInput : String -> String -> String -> (String -> Msg) -> Html Msg
viewInput t p v toMsg =
  input [ class "input is-rounded", type_ t, placeholder p, value v, onInput toMsg ] []

viewValidationButton : Model -> Html Msg
viewValidationButton model =
    case model.newApplicationName of
        "" -> button [ class "button has-background-info has-text-white", onClick CreateNewApplication, attribute "aria-label" "save", attribute "disabled" "true"] [ text "作成" ]
        _ -> button [ class "button has-background-info has-text-white", onClick CreateNewApplication, attribute "aria-label" "save" ] [ text "作成" ]
