module UserOperation exposing (..)
import Types.User exposing (User, avatarURL)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Api
import Url.Builder exposing (absolute)
import Types.Transactions exposing (transactionsEncoder)


type alias Model =
    { user_id : String
    , show_modal : Bool
    , modal_type : ModalType
    , access_token : String
    , amount : String
    , unit : String
    , error_notice : Maybe String
    , success_notice : Maybe String
    }


defaultModel : String -> Model
defaultModel access_token =
    { user_id = ""
    , show_modal = False
    , modal_type = Pay
    , access_token = access_token
    , amount = ""
    , unit = ""
    , error_notice = Maybe.Nothing
    , success_notice = Maybe.Nothing
    }


type ModalType
    = Pay


createTransaction : Model -> Cmd Msg
createTransaction model =
    Api.post
        { url = absolute ["api", "v2", "users", "@me", "transactions"] []
        , token = model.access_token
        , expect = Http.expectWhatever GotTransaction
        , body = Http.jsonBody (transactionsEncoder model.unit model.user_id model.amount)
        }


type Msg
    = ShowModal String String String ModalType
    | ClosePopup
    | ChangeID String
    | ChangeAmount String
    | ChangeUnit String
    | GotTransaction (Result Http.Error ())
    | Submit

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowModal user amount unit type_ ->
            ( { model | user_id = user, modal_type = type_, show_modal = True, amount = amount, unit = unit}, Cmd.none )
        ClosePopup ->
            ( { model | show_modal = False, error_notice = Maybe.Nothing, success_notice = Maybe.Nothing}, Cmd.none )
        ChangeID i ->
            ( { model | user_id = i }, Cmd.none)
        ChangeAmount amount ->
            ( { model | amount = amount }, Cmd.none)
        ChangeUnit unit ->
            ( { model | unit = unit }, Cmd.none)
        Submit ->
            ( model, createTransaction model)
        GotTransaction result ->
            case result of
                Ok () ->
                    ( { model | success_notice = Just (model.amount ++ " " ++ model.unit ++ "の送金が完了しました。") }, Cmd.none )
                Err _ ->
                    ( { model | error_notice = Just "失敗しました。所持数が足りないか、単位を間違えています。" }, Cmd.none )


view : Model -> Html Msg
view model =
    if model.show_modal
        then
            case model.modal_type of
                Pay -> payView model
        else text ""


payView : Model -> Html Msg
payView model =
    div [ class "modal is-active", attribute "aria-label" "新規アプリケーション作成" ]
        [ div [ class "modal-background", onClick ClosePopup ] []
        , div [ class "modal-card"]
            [ header [class "modal-card-head"]
                [ p [class "modal-card-title has-text-info has-text-weight-bold"] [text "送金"]
                , button [class "delete", attribute "aria-label" "close", onClick ClosePopup] []
                ]
            , section [class "modal-card-body"]
                [ payViewBody model
                ]
            , footer [class "modal-card-foot"]
                [ payViewSubmitButton model
                , button [class "button", onClick ClosePopup] [text "閉じる"]
                ]
            ]
        ]


payViewSubmitValidation : Model -> Bool
payViewSubmitValidation model =
    if (String.toInt model.amount) == Maybe.Nothing
        then False
    else if (String.toInt model.user_id) == Maybe.Nothing
        then False
    else if model.unit == ""
        then False
        else True


payViewSubmitButton : Model -> Html Msg
payViewSubmitButton model =
    if payViewSubmitValidation model
        then button [class "button has-background-info has-text-white", onClick Submit] [text "送金"]
        else button [class "button has-background-info has-text-white", attribute "disabled" "true"] [text "送金"]





payViewBody : Model -> Html Msg
payViewBody model =
    div [class "my-3 ml-2"]
        [ sec "送金先DiscordユーザーID"
        , input [type_ "number", placeholder "212513828641046529", value model.user_id, onInput ChangeID, class "input"] []
        , sec "送金金額"
        , input [type_ "number", placeholder "100", value model.amount, onInput ChangeAmount, class "input"] []
        , sec "送金する通貨の単位"
        , input [type_ "text", placeholder "v", value model.unit, onInput ChangeUnit, class "input"] []
        , errorView model
        , successView model
        ]


errorView : Model -> Html Msg
errorView model =
    case model.error_notice of
        Maybe.Nothing -> text ""
        Just s ->
            div [class "notification is-danger mt-3"]
                [ strong [] [text s]
                ]


successView : Model -> Html Msg
successView model =
    case model.success_notice of
            Maybe.Nothing -> text ""
            Just s ->
                div [class "notification is-success mt-3"]
                    [ strong [] [text s]
                    ]


sec : String -> Html Msg
sec s =
    div [class "has-text-weight-bold mt-2"] [text s]


username : User -> Html Msg
username u =
    div [class "dropdown is-hoverable"]
        [ div [class "dropdown-trigger"]
            [ p [attribute "aria-haspopup" "true", attribute "aria-controls" "dropdown-menu"]
                [ span [class "has-text-info has-text-weight-bold"] [text <| "@" ++ u.discord.username ++ "#" ++ u.discord.discriminator]
                ]
            ]
        , div [class "dropdown-menu", id "dropdown-menu", attribute "role" "menu"]
            [ div [class "dropdown-content"]
                [ div [class "dropdown-item"]
                    [ figure [class "image is-128x128"]
                        [ img [class "is-rounded", src <| avatarURL u] []
                        ]
                    ]
                , div [class "dropdown-item"]
                    [ p [class "has-text-weight-bold has-text-centered is-size-4"] [text <| u.discord.username ++ "#" ++ u.discord.discriminator]
                    ]
                , hr [class "dropdown-divider"] []
                , a [class "dropdown-item my-2 has-text-info has-text-weight-bold", onClick (ShowModal u.discord.id "" "" Pay)] [text "送金"]
                --, a [class "dropdown-item my-2 has-text-info has-text-weight-bold", onClick (ShowModal u Claim)] [text "請求"]
                ]
            ]
        ]

pay_card_footer : String -> String -> String -> String -> Html Msg
pay_card_footer txt discord_id amount unit =
    a [ class "card-footer-item has-text-info has-text-weight-bold", onClick (ShowModal discord_id amount unit Pay)  ] [ text txt ]
