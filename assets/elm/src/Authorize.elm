module Authorize exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import String


type alias AuthorizationInfo =
    { redirect_uri : String, state : Maybe String, scope : List String, client_id : String, response_type : String, guild_id : String }


type alias Model =
    { authorization_info : AuthorizationInfo, csrf_token : String }


type alias Flags =
    { redirect_uri : String, state : Maybe String, scope : String, client_id : String, csrf_token : String, response_type : String,guild_id : String }


type alias Msg
    = Never


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init data =
    let
        { redirect_uri, state, scope, client_id, response_type, guild_id } =
            data
    in
    ( { authorization_info = { redirect_uri = redirect_uri, state = state, scope = String.split " " scope, client_id = client_id, response_type = response_type, guild_id = guild_id }, csrf_token = data.csrf_token }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        { redirect_uri, state, scope, client_id, response_type,guild_id } =
            model.authorization_info
    in
    div []
        [ Html.form [ action "./authorize", method "post" ]
            (Maybe.withDefault [] (Maybe.map (\s -> [ hidden_input "state" s ]) state)
                ++ [ hidden_input "redirect_uri" redirect_uri
                   , hidden_input "scope" (String.join " " scope)
                   , hidden_input "client_id" client_id
                   , hidden_input "_csrf_token" model.csrf_token
                   , hidden_input "response_type" response_type
                   , hidden_input "guild_id" guild_id
                   , common_button "approve" "Approve"
                   ]
            )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


button_class : String
button_class =
    "button is-info mx-2 is-large px-6"


common_button : String -> String -> Html msg
common_button value_ text_ =
    button [ class button_class, value value_, name "action" ] [ text text_ ]


hidden_input : String -> String -> Html msg
hidden_input name_ value_ =
    input [ type_ "hidden", name name_, value value_ ] []
