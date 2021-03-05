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
    }


type Msg
    = InjectUserdata User
    | GotBalances (Result Http.Error Balances)
    | Previous
    | Next


init : String -> Maybe User -> ( Model, Cmd msg )
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


view : Model -> Html Msg
view model =
    div [ class "column" ]
        [ userInfo model
        , div [ class "columns" ]
            [ div [ class "column is-two-fifths" ]
                (case model.balances of
                    Value balances ->
                        [ div [ class "has-text-weight-bold is-size-3 ml-2 my-3" ] [ text "所持通貨" ]
                        , balances |> filterDataWithPage model.page |> List.map balanceView |> div []
                        , nav [ class "pagination" ]
                            [ if model.page /= 0 then
                                a [ onClick Previous, class "pagination-previous" ] [ text "前ページ" ]

                              else
                                text ""
                            , if model.page /= getMaxPage balances then
                                a [ onClick Next, class "pagination-next" ] [ text "次ページ" ]

                              else
                                text ""
                            ]
                        ]

                    Pending ->
                        [ div [ class "is-size-2 mx-5" ] [ text "Loading..." ] ]

                    Failed ->
                        [ div [ class "is-size-2 mx-5" ] [ text "Failed..." ] ]
                )
            ]
        ]


userInfo : Model -> Html msg
userInfo model =
    div [ class "columns" ]
        [ div [ class "column is-2" ]
            [ img
                [ class "circle"
                , src
                    (Maybe.withDefault "https://cdn.discordapp.com/embed/avatars/0.png?size=128"
                        (Maybe.map avatarURL
                            (case model.userData of
                                Value d ->
                                    Just d

                                _ ->
                                    Nothing
                            )
                        )
                    )
                , height 100
                , width 100
                ]
                []
            ]
        , div [ class "column" ]
            [ div [ class "has-text-weight-bold is-size-3 mt-5" ]
                (Maybe.withDefault []
                    (Maybe.map
                        (\discordUserData -> [ text ("こんにちは、" ++ discordUserData.username ++ "#" ++ discordUserData.discriminator ++ " さん") ])
                        (case model.userData of
                            Value d ->
                                Just d.discord

                            _ ->
                                Nothing
                        )
                    )
                )
            ]
        ]


filterDataWithPage : Int -> Balances -> Balances
filterDataWithPage page data =
    toList <| slice (page * 5) (page * 5 + 4) (fromList data)


balanceView : Balance -> Html msg
balanceView balance =
    div [ class "card my-3" ]
        [ div [ class "card-content" ]
            [ div [ class "media" ]
                [ div [ class "media-left has-text-weight-bold" ] [ text balance.currency.name ]
                , div [ class "media-content mr-2" ] [ text (balance.amount ++ balance.currency.unit) ]
                ]
            ]
        , footer [ class "card-footer" ]
            [ div [ class "card-footer-item" ] [ text "詳細" ]
            , div [ class "card-footer-item" ] [ text "取引履歴" ]
            , div [ class "card-footer-item" ] [ text "送金" ]
            ]
        ]


getBalances : String -> Cmd Msg
getBalances token =
    Api.get
        { url = absolute [ "api", "v1", "users", "@me", "balances" ] []
        , expect = Http.expectJson GotBalances balancesDecoder
        , token = token
        }
