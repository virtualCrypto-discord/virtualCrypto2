module Application exposing (..)

import Browser
import Browser.Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Maybe exposing (withDefault)
import Html.Events exposing (..)
import Types.Applications exposing (TokenEndpointResponse, tokenEndpointDecoder, ApplicationInfo, clientConfigurationRequestEncoder)
import Api
import Url.Builder exposing (absolute, string)
import Http
import Base64

type alias Model =
    { application : ApplicationInfo
    , edit : Bool
    , refresh_secret : Bool
    , token : Maybe String
    }

type Msg =
      EditName String
    | EditLogo String
    | EditSlug String
    | EditURI String
    | GotToken (Result Http.Error TokenEndpointResponse)
    | GotPatchResponse (Result Http.Error ())
    | Save
    | Regenerate

getToken : String -> String -> Cmd Msg
getToken id secret =
    Api.post2
        { url = absolute [ "oauth2", "token" ] [string "grant_type" "client_credentials", string "scope" "oauth2.register"]
        , expect = Http.expectJson GotToken tokenEndpointDecoder
        , token = Base64.encode (id ++ ":" ++ secret)
        }

patchData : String -> ApplicationInfo -> Bool -> Cmd Msg
patchData token app refresh_secret =
    Api.patch
        { url = absolute [ "oauth2", "clients", "@me"] []
        , expect = Http.expectWhatever GotPatchResponse
        , token = token
        , body = Http.jsonBody (clientConfigurationRequestEncoder app refresh_secret)
        }


main : Program ApplicationInfo Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }

init : ApplicationInfo -> ( Model, Cmd Msg )
init flags =
    ({application = flags, edit = False, refresh_secret = False, token = Maybe.Nothing}, Cmd.none)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        application = model.application
    in
    case msg of
        EditName name ->
            ({model | application = { application | client_name = getString name}, edit = True}, Cmd.none)
        EditLogo logo ->
            ({model | application = { application | logo_uri = getString logo}, edit = True}, Cmd.none)
        EditSlug slug ->
            ({model | application = { application | discord_support_server_invite_slug = Just slug}, edit = True}, Cmd.none)
        EditURI uri ->
            ({model | application = { application | client_uri = getString uri}, edit = True}, Cmd.none)
        GotToken result ->
            case result of
                Ok data ->
                    ( {model | token = getString data.access_token}, patchData data.access_token model.application model.refresh_secret)
                Err _ -> (model, Cmd.none)
        GotPatchResponse result ->
            case result of
                Ok _ ->
                    ( {model | edit = False}, Browser.Navigation.reload )
                Err _ ->
                    (model, Cmd.none)
        Save ->
            (model, getToken model.application.client_id model.application.client_secret)
        Regenerate ->
            ({model | refresh_secret = True}, getToken model.application.client_id model.application.client_secret)


view : Model -> Html Msg
view model =
    div [class "columns"]
        [ div [class "column is-7 is-offset-1"]
            [ div [class "is-size-3 has-text-weight-bold mb-3"] [text "アプリケーションの詳細"]
            , div [class "ml-5"]
                [ sec "名前"
                , viewInput "名前" (withDefault "" model.application.client_name) (EditName)
                , sec "ロゴURL"
                , viewInput "ロゴURL" (withDefault "" model.application.logo_uri) (EditLogo)
                , sec "サポートサーバーの招待url"
                , viewInput "pcr5GRvQ" (withDefault "" model.application.discord_support_server_invite_slug) (EditSlug)
                , sec "webサイトのurl"
                , viewInput "https://vcrypto.sumidora.com" (withDefault "" model.application.client_uri) (EditURI)
                , sec "クライアントID"
                , showInput model.application.client_id
                , sec "クライアントシークレット"
                , button [ class "button has-background-info has-text-white my-2", onClick Regenerate] [ text "再生成" ]
                , showInput model.application.client_secret
                , saveButton model
                ]
            ]
        ]

maybeText : String -> Maybe String -> Html msg
maybeText d t = text (withDefault d t)

viewInput : String -> String -> (String -> Msg) -> Html Msg
viewInput p v toMsg =
    input [ type_ "text", placeholder p, value v, onInput toMsg, class "input" ] []

showInput : String -> Html Msg
showInput v =
    input [ type_ "text", value v, class "input", readonly True] []

sec : String -> Html Msg
sec t = div [class "has-text-weight-bold mt-2"] [text t]

saveButton : Model -> Html Msg
saveButton model =
    if model.edit
        then button [ class "button has-background-info has-text-white mt-3", onClick Save] [ text "保存" ]
        else button [ class "button has-background-info has-text-white mt-3", attribute "disabled" ""] [ text "保存" ]

getString : String -> Maybe String
getString s =
    if s == ""
        then Maybe.Nothing
        else Just s
