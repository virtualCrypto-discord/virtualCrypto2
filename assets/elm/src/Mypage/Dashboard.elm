module Mypage.Dashboard exposing (..)

import Api
import Array exposing (fromList, slice, toList)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Types.Balance exposing (Balance, Balances, balancesDecoder)
import Types.User exposing (User, avatarURL)
import Url.Builder exposing (absolute)
import UserOperation


getMaxPage : Balances -> Int
getMaxPage data =
    List.length data // 5


type DynamicData x
    = Pending
    | Failed
    | Value x


type alias Model =
    { userData : DynamicData User
    , accessToken : String
    , balances : DynamicData Balances
    , page : Int
    , user_operation_model : UserOperation.Model
    }


type Msg
    = InjectUserdata User
    | GotBalances (Result Http.Error Balances)
    | Previous
    | Next
    | UserOperationMsg UserOperation.Msg


init : String -> Maybe User -> ( Model, Cmd Msg )
init accessToken userData =
    ( { accessToken = accessToken
      , userData =
            case userData of
                Maybe.Just d ->
                    Value d

                Maybe.Nothing ->
                    Pending
      , balances = Pending
      , page = 0
      , user_operation_model = UserOperation.defaultModel accessToken
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InjectUserdata userData ->
            ( { model | userData = Value userData }, getBalances model.accessToken )

        GotBalances result ->
            case result of
                Ok data ->
                    ( { model | balances = Value data }, Cmd.none )

                Err _ ->
                    ( { model | balances = Failed }, Cmd.none )

        Previous ->
            case model.page of
                0 ->
                    ( model, Cmd.none )

                _ ->
                    ( { model | page = model.page - 1 }, Cmd.none )

        Next ->
            case model.balances of
                Value balances ->
                    if model.page == getMaxPage balances then
                        ( model, Cmd.none )

                    else
                        ( { model | page = model.page + 1 }, Cmd.none )

                _ ->
                    ( model, Cmd.none )
        UserOperationMsg msg_ ->
            let
                ( m_, cmd ) = UserOperation.update msg_ model.user_operation_model
            in
            ( { model | user_operation_model = m_ }, Cmd.map UserOperationMsg cmd)


view : Model -> Html Msg
view model =
    div [class "items"]
        [ topItem model
        , centerItem model
        , bottomItem model
        ]


topItem : Model -> Html Msg
topItem model =
    div [class "top-item"]
        [ div [class "coin-info-list"]
            [ div [class "coin-info"]
                [ div [class "coin-info-title"] [text "VCoin"]
                , div [class "coin-info-value"] [text "12003v"]
                ]
            , div [class "coin-info"]
                [ div [class "coin-info-title"] [text "VCoin"]
                , div [class "coin-info-value"] [text "12003v"]
                ]
            , div [class "coin-info"]
                [ div [class "coin-info-title"] [text "VCoin"]
                , div [class "coin-info-value"] [text "12003v"]
                ]
            , div [class "coin-info"]
                [ div [class "coin-info-title"] [text "VCoin"]
                , div [class "coin-info-value"] [text "12003v"]
                ]

            ]
        , button [] [text "さらに見る"]
        ]

centerItem : Model -> Html Msg
centerItem model =
    div [class "center-item"]
        [ div [class "left-item"]
            [ header []
                [ div [class "my-tabs"]
                    [ ul []
                        [ li [class "is-selected"] [a [class "is-selected"] [text "もらった請求"]]
                        , li [] [a [] [text "自分の請求"]]
                        ]
                    ]
                , button [] [text "さらに見る"]
                ]
            , div [class "scroll-table"]
                [ table []
                    [ tr []
                        [ th [] [text "ID"]
                        , th [] [text "ユーザー"]
                        , th [] [text "通貨の種類"]
                        , th [] [text "数量"]
                        , th [] [text "日時"]
                        ]
                    , demodata
                    , demodata
                    , demodata
                    , demodata
                    , demodata
                    , demodata
                    ]
                ]
            ]
        , div [class "right-item"] []
        ]

demodata : Html Msg
demodata =
    tr []
        [ td [] [text "value1"]
        , td [] [text "value2"]
        , td [] [text "value3"]
        , td [] [text "value4"]
        , td [] [text "value5"]
        ]

bottomItem : Model ->  Html Msg
bottomItem model =
    div [class "bottom-item"]
        [ div [class "left-item"] []
        , div [class "right-item"] []
        ]


filterDataWithPage : Int -> Balances -> Balances
filterDataWithPage page data =
    toList <| slice (page * 5) (page * 5 + 4) (fromList data)


balanceView : Balance -> Html Msg
balanceView balance =
    text "abc"


boldText : String -> Html Msg
boldText s =
    span [class "has-text-weight-bold"] [text s]

unitText: String -> Html Msg
unitText s =
    span [class "ml-1"] [text s]



getBalances : String -> Cmd Msg
getBalances token =
    Api.get
        { url = absolute [ "api", "v1", "users", "@me", "balances" ] []
        , expect = Http.expectJson GotBalances balancesDecoder
        , token = token
        }
