module Mypage.Claim exposing (..)

import Api
import Array exposing (fromList, slice, toList)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Mypage.Dashboard exposing (DynamicData(..))
import Types.User exposing (User)
import Types.Claim exposing (Claims,claimsDecoder,Claim)
import Platform exposing (Task)
import Task exposing (Task)
import Url.Builder exposing (absolute)

type ClaimType
    = Sent
    | Received

type AsyncData
    = LoadingUserData
    | LoadingClaims User
    | Completed GroupedClaims


type alias GroupedClaims =
    { sent : Claims
    , received : Claims
    }


type alias Model =
    { accessToken : String
    , asyncData : AsyncData
    , sent_page : Int
    , received_page : Int
    }


type Msg
    = InjectUserData User
    | GotClaims (Result Http.Error GroupedClaims)
    | Previous ClaimType
    | Next ClaimType


getClaims : String -> String -> Task Http.Error GroupedClaims
getClaims id token =
    Task.map (gropingClaims id)
        (Api.getTask
            { url = absolute [ "api", "v1", "users", "@me", "claims" ] []
            , decoder = claimsDecoder
            , token = token
            }
        )


init : String -> Maybe User -> ( Model, Cmd Msg )
init accessToken userData =
    ( { accessToken = accessToken
      , asyncData = Maybe.withDefault LoadingUserData (Maybe.map LoadingClaims userData)
      , sent_page = 0
      , received_page = 0
      }
    , Cmd.none
    )


getPrevious : Int -> Int
getPrevious page =
    case page of
        0 ->
            0

        p ->
            p - 1


getNext : Int -> Int -> Int
getNext page max_page =
    if page == max_page then
        page

    else
        page + 1


gropingClaims : String -> Claims -> GroupedClaims
gropingClaims id claims =
    List.foldl
        (\claim acc ->
            { sent =
                if claim.claimant.id == id then
                    claim :: acc.sent

                else
                    acc.sent
            , received =
                if claim.payer.id == id then
                    claim :: acc.received

                else
                    acc.received
            }
        )
        { sent = []
        , received = []
        }
        claims


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InjectUserData userData ->
            ( { model | asyncData = LoadingClaims userData }, Task.attempt GotClaims (getClaims userData.id model.accessToken) )

        GotClaims result ->
            case result of
                Ok data ->
                    ( { model | asyncData = Completed data }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        Previous t ->
            case t of
                Received ->
                    ( { model | received_page = getPrevious model.received_page }, Cmd.none )

                Sent ->
                    ( { model | sent_page = getPrevious model.sent_page }, Cmd.none )

        Next t ->
            case t of
                Received ->
                    case model.asyncData of
                        Completed claims ->
                            ( { model | received_page = getNext model.received_page (getMaxPage claims.received) }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Sent ->
                    case model.asyncData of
                        Completed claims ->
                            ( { model | sent_page = getNext model.sent_page (getMaxPage claims.sent) }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model.asyncData of
        Completed claims ->
            claimView model claims

        _ ->
            loadingView


claimView : Model -> GroupedClaims -> Html Msg
claimView model claims =
    div [ class "column" ]
        [ div [ class "columns" ]
            [ div [ class "column is-three-quarters" ]
                [ receivedClaimsView model claims
                , sentClaimsView model claims
                ]
            ]
        ]

sentClaimsView : Model -> GroupedClaims -> Html Msg
sentClaimsView model claims =
    div []
        [ title "自分の請求"
        , claims.sent |> filterDataWithPage model.sent_page |> List.sortWith compareString |> List.map sentClaimView |> div [class "columns is-multiline"]
        , nav [ class "pagination" ]
            [ previousButton Sent (model.sent_page == 0)
            , nextButton Sent (model.sent_page == getMaxPage claims.sent)
            ]
        ]

receivedClaimsView : Model -> GroupedClaims -> Html Msg
receivedClaimsView model claims =
    div []
        [ title "自分に来た請求"
        , claims.received |> filterDataWithPage model.received_page |> List.sortWith compareString |> List.map receivedClaimView |> div [class "columns is-multiline"]
        , nav [ class "pagination" ]
            [ previousButton Received (model.received_page == 0)
            , nextButton Received (model.received_page == getMaxPage claims.received)
            ]
        ]



loadingView : Html msg
loadingView =
    div [ class "is-size-2 mx-5" ] [ text "Loading..." ]


title : String -> Html msg
title text_ =
    div [ class "is-size-3 has-text-weight-bold my-5" ] [ text text_ ]


previousButton : ClaimType -> Bool -> Html Msg
previousButton t d =
    a [ onClick (Previous t), class "pagination-previous", disabled d ] [ text "前ページ" ]


nextButton : ClaimType -> Bool -> Html Msg
nextButton t d =
    a [ onClick (Next t), class "pagination-next", disabled d ] [ text "次ページ" ]


sentClaimView : Claim -> Html Msg
sentClaimView claim =
    div [class "column is-half"]
        [ div [ class "card my-3" ]
            [ header [class "card-header has-background-info-light"]
                [ p [class "card-header-title"] [text ("ID: " ++ claim.id)]
                ]
            , div [class "card-content"]
                [ div [class "content"] [text <| "請求先ユーザー: " ++ (username claim.payer)]
                , div [class "content"] [text "請求量: ", boldText claim.amount, unitText claim.currency.unit]
                ]
            , footer [class "card-footer"]
                [ div [class "card-footer-item"] [text <| "請求日時: " ++ claim.created_at]
                , a [class "card-footer-item"] []
                , a [class "card-footer-item"] []
                ]
            ]
        ]


username : User -> String
username u =
    "@" ++ u.discord.username ++ "#" ++ u.discord.discriminator


receivedClaimView : Claim -> Html Msg
receivedClaimView claim =
    div [class "column is-half"]
        [ div [ class "card my-3" ]
            [ header [class "card-header has-background-info-light"]
                [ p [class "card-header-title"] [text ("ID: " ++ claim.id)]
                ]
            , div [class "card-content"]
                [ div [class "content"] [text <| "請求元ユーザー: " ++ (username claim.claimant)]
                , div [class "content"] [text "請求量: ", boldText claim.amount, unitText claim.currency.unit]
                ]
            , footer [class "card-footer"]
                [ div [class "card-footer-item"] [text <| "請求日時: " ++ claim.created_at]
                , a [class "card-footer-item"] []
                , a [class "card-footer-item"] []
                ]
            ]
        ]


filterDataWithPage : Int -> List Claim -> List Claim
filterDataWithPage page data =
    toList <| slice (page * 20) (page * 2 + 19) (fromList data)


getMaxPage : List Claim -> Int
getMaxPage data =
    List.length data // 20

boldText : String -> Html Msg
boldText s =
    span [class "has-text-weight-bold"] [text s]

unitText: String -> Html Msg
unitText s =
    span [class "ml-1"] [text s]


compareString l r =
    compare (String.toInt l.id |> Maybe.withDefault 0) (String.toInt r.id |> Maybe.withDefault 0)

