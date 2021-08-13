port module Application exposing (..)

import Api
import Base64
import Browser
import Browser.Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder)
import Maybe exposing (withDefault)
import Types.Applications exposing (ApplicationInfo, Applications, ClientRegistrationPatchErrorResponse, TokenEndpointResponse, clientConfigurationRequestEncoder, clientRegistrationPatchErrorResponseDecoder, tokenEndpointDecoder)
import Url exposing (Protocol(..))
import Url.Builder exposing (absolute, string)


type alias Model =
    { application : ApplicationInfo
    , edit : Bool
    , refresh_secret : Bool
    , token : Maybe String
    , result_string : Maybe String
    }


type Msg
    = EditName String
    | EditLogo String
    | EditSlug String
    | EditWebsiteURI String
    | EditWebhookURL String
    | GotToken (Result Http.Error TokenEndpointResponse)
    | GotPatchResponse (Result CustomError ())
    | Save
    | Regenerate
    | Copy String


type CustomError
    = UnknownError
    | BadStatus ClientRegistrationPatchErrorResponse


expectJsonWithError : (Result CustomError () -> msg) -> Http.Expect msg
expectJsonWithError toMsg =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ _ ->
                    Err UnknownError

                Http.Timeout_ ->
                    Err UnknownError

                Http.NetworkError_ ->
                    Err UnknownError

                Http.BadStatus_ _ body ->
                    case Json.Decode.decodeString clientRegistrationPatchErrorResponseDecoder body of
                        Ok value ->
                            Err (BadStatus value)

                        Err _ ->
                            Err UnknownError

                Http.GoodStatus_ _ _ ->
                    Ok ()


getToken : String -> String -> Cmd Msg
getToken id secret =
    Api.post2
        { url = absolute [ "oauth2", "token" ] [ string "grant_type" "client_credentials", string "scope" "oauth2.register" ]
        , expect = Http.expectJson GotToken tokenEndpointDecoder
        , token = Base64.encode (id ++ ":" ++ secret)
        }


patchData : String -> ApplicationInfo -> Bool -> Cmd Msg
patchData token app refresh_secret =
    Api.patch
        { url = absolute [ "oauth2", "clients", "@me" ] []
        , expect = expectJsonWithError GotPatchResponse
        , token = token
        , body = Http.jsonBody (clientConfigurationRequestEncoder app refresh_secret)
        }


main : Program ApplicationInfo Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : ApplicationInfo -> ( Model, Cmd Msg )
init flags =
    ( { application = flags, edit = False, refresh_secret = False, token = Maybe.Nothing, result_string = Maybe.Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        application =
            model.application
    in
    case msg of
        EditName name ->
            ( { model | application = { application | client_name = getString name }, edit = True }, Cmd.none )

        EditLogo logo ->
            ( { model | application = { application | logo_uri = getString logo }, edit = True }, Cmd.none )

        EditSlug slug ->
            ( { model | application = { application | discord_support_server_invite_slug = Just slug }, edit = True }, Cmd.none )

        EditWebsiteURI uri ->
            ( { model | application = { application | client_uri = getString uri }, edit = True }, Cmd.none )

        EditWebhookURL url ->
            ( { model | application = { application | webhook_url = getString url }, edit = True }, Cmd.none )

        GotToken result ->
            case result of
                Ok data ->
                    ( { model | token = getString data.access_token }, patchData data.access_token model.application model.refresh_secret )

                Err _ ->
                    ( model, Cmd.none )

        GotPatchResponse result ->
            case result of
                Ok _ ->
                    ( { model | edit = False }, Browser.Navigation.reload )

                Err err ->
                    case err of
                        BadStatus v ->
                            ( { model | edit = True, result_string = Maybe.Just (v.error ++ (v.error_description |> Maybe.map (\x -> "(" ++ x ++ ")") |> Maybe.withDefault "")) }, Cmd.none )

                        _ ->
                            ( { model | edit = True, result_string = Maybe.Just "unknown error" }, Cmd.none )

        Save ->
            ( { model | edit = False }, getToken model.application.client_id model.application.client_secret )

        Regenerate ->
            ( { model | refresh_secret = True }, getToken model.application.client_id model.application.client_secret )

        Copy t ->
            ( model, copy t )


port copy : String -> Cmd msg


view : Model -> Html Msg
view model =
    div [ class "columns" ]
        [ div [ class "column is-7 is-offset-1" ]
            [ div [ class "is-size-3 has-text-weight-bold mb-3" ] [ text "アプリケーションの詳細" ]
            , div [ class "ml-5" ]
                [ a [ href ("/applications/" ++ model.application.client_id ++ "/connect"), class "button has-background-info has-text-white my-2" ] [ text "Discord Botと紐つける" ]
                , sec "名前"
                , viewInput "名前" (withDefault "" model.application.client_name) EditName
                , sec "ロゴURL"
                , viewInput "ロゴURL" (withDefault "" model.application.logo_uri) EditLogo
                , sec "サポートサーバーの招待url"
                , viewInput "pcr5GRvQ" (withDefault "" model.application.discord_support_server_invite_slug) EditSlug
                , sec "webサイトのurl"
                , viewInput "https://vcrypto.sumidora.com" (withDefault "" model.application.client_uri) EditWebsiteURI
                , sec "webhookを受け取るurl"
                , viewInput "https://vcrypto.sumidora.com/webhook" (withDefault "" model.application.webhook_url) EditWebhookURL
                , sec "クライアントID"
                , showInput model.application.client_id "client_id"
                , copyButton "#client_id"
                , sec "公開鍵"
                , showInput model.application.public_key "public_key"
                , copyButton "#public_key"
                , sec "クライアントシークレット"
                , showInput model.application.client_secret "client_secret"
                , div []
                    [ copyButton "#client_secret"
                    , button [ class "button has-background-info has-text-white my-2", onClick Regenerate ] [ text "再生成" ]
                    ]
                , saveButton model
                , p []
                    [ text (Maybe.withDefault "" model.result_string) ]
                ]
            ]
        ]


viewInput : String -> String -> (String -> Msg) -> Html Msg
viewInput p v toMsg =
    input [ type_ "text", placeholder p, value v, onInput toMsg, class "input" ] []


showInput : String -> String -> Html Msg
showInput v id_ =
    input [ type_ "text", value v, class "input", readonly True, id id_ ] []


sec : String -> Html Msg
sec t =
    div [ class "has-text-weight-bold mt-2" ] [ text t ]


saveButton : Model -> Html Msg
saveButton model =
    if model.edit then
        button [ class "button has-background-info has-text-white mt-3", onClick Save ] [ text "保存" ]

    else
        button [ class "button has-background-info has-text-white mt-3", attribute "disabled" "" ] [ text "保存" ]


copyButton : String -> Html Msg
copyButton t =
    button [ class "button my-2 mr-3 has-background-info has-text-white", onClick (Copy t) ] [ text "コピー" ]


getString : String -> Maybe String
getString s =
    if s == "" then
        Maybe.Nothing

    else
        Just s
