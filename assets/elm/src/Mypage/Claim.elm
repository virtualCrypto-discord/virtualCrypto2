module Mypage.Claim exposing (..)
import Url.Builder exposing (absolute)
import Api
import Json.Decode exposing (field, Decoder, map2, map6, string, int)
import Array exposing (fromList, slice, toList)
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)

type alias User =
    { name : String }

type alias Claim =
    { id : String
    , unit : String
    , amount : String
    , claimant : User
    , payer : User
    , created_at : String
    }

type ClaimType
    = Sent
    | Received

type alias Claims =
    { sent : List Claim
    , received : List Claim
    }

type alias Model =
    { claims : Maybe Claims
    , sent_page : Int
    , received_page : Int
    }


claimsDecoder : Decoder Claims
claimsDecoder =
    map2 Claims
        (field "sent" claimDecoder)
        (field "received" claimDecoder)


claimDecoder : Decoder (List Claim)
claimDecoder =
    map6 Claim
        (field "id" string)
        (field "unit" string)
        (field "amount" string)
        (field "claimant" userDecoder)
        (field "payer" userDecoder)
        (field "created_at" string)
    |> Json.Decode.list


userDecoder : Decoder User
userDecoder =
    Json.Decode.map User
        (field "name" string)

type Msg
    = GotClaims (Result Http.Error Claims)
    | Previous ClaimType
    | Next ClaimType

getClaims : String -> Cmd Msg
getClaims token =
    Api.get
        { url = absolute [ "api", "v1", "users", "@me", "claims" ] []
        , expect = Http.expectJson GotClaims claimsDecoder
        , token = token
        }

initCmd : String -> Cmd Msg
initCmd accessToken =
    getClaims accessToken

initModel : String -> Model
initModel _ =
    { claims = Maybe.Nothing
    , sent_page = 0
    , received_page = 0
    }

getPrevious : Int -> Int
getPrevious page =
    case page of
        0 -> 0
        p -> p - 1

getNext : Int -> Int -> Int
getNext page max_page =
    if page == max_page
        then page
        else page + 1

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotClaims result ->
            case result of
                Ok data ->
                    ( { model | claims = Just data}, Cmd.none )
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
                    case model.claims of
                        Just claims -> ( { model | received_page = getNext model.received_page (getMaxPage claims.received)}, Cmd.none )
                        Nothing -> (model, Cmd.none)
                Sent ->
                    case model.claims of
                        Just claims -> ( { model | sent_page = getNext model.sent_page (getMaxPage claims.sent)}, Cmd.none )
                        Nothing -> (model, Cmd.none)


view : Model -> Html Msg
view model =
    case model.claims of
        Just claims -> claimView model claims
        Nothing -> loadingView

claimView : Model -> Claims -> Html Msg
claimView model claims =
    div [ class "column" ]
        [ div [ class "columns" ]
            [ div [ class "column is-three-quarters" ]
                [ title "自分に来た請求"
                , receivedHeader
                , claims.received |> filterDataWithPage model.received_page |> List.map receivedClaimView |> div []
                , nav [ class "pagination" ]
                    [ previousButton Received (model.received_page == 0)
                    , nextButton Received (model.received_page == getMaxPage claims.received)
                    ]
                , title "自分の請求"
                , sentHeader
                , claims.sent |> filterDataWithPage model.sent_page |> List.map sentClaimView |> div []
                , nav [ class "pagination" ]
                    [ previousButton Sent (model.sent_page == 0)
                    , nextButton Sent (model.sent_page == getMaxPage claims.sent)
                    ]
                ]
            ]
        ]

loadingView : Html msg
loadingView = div [class "is-size-2 mx-5"] [text "Loading..."]

title : String -> Html msg
title text_ = div [class "is-size-3 has-text-weight-bold my-5"] [ text text_ ]

previousButton : ClaimType -> Bool -> Html Msg
previousButton t d = a [ onClick (Previous t), class "pagination-previous", disabled d ] [ text "前ページ" ]

nextButton : ClaimType -> Bool -> Html Msg
nextButton t d = a [ onClick (Next t), class "pagination-next", disabled d ] [ text "次ページ" ]

sentHeader =
    div [ class "card my-3" ]
        [ div [ class "card-content" ]
            [ div [ class "media" ]
                [ div [ class "media-left has-text-weight-bold" ] [ text "ID" ]
                , div [ class "media-content mr-2 has-text-weight-bold" ] [ text "請求先" ]
                , div [ class "media-content mr-2 has-text-weight-bold" ] [ text "請求量" ]
                , div [ class "media-right mr-2" ] [ text "請求日" ]
                ]
            ]
        ]


sentClaimView : Claim -> Html Msg
sentClaimView claim =
    div [ class "card my-3" ]
        [ div [ class "card-content" ]
            [ div [ class "media" ]
                [ div [ class "media-left has-text-weight-bold" ] [ text claim.id ]
                , div [ class "media-content mr-2" ] [ text claim.payer.name ]
                , div [ class "media-content mr-2" ] [ text (claim.amount ++ claim.unit) ]
                , div [ class "media-right mr-2" ] [ text claim.created_at ]
                ]
            ]
        ]

receivedHeader =
    div [ class "card my-3" ]
        [ div [ class "card-content" ]
            [ div [ class "media" ]
                [ div [ class "media-left has-text-weight-bold" ] [ text "ID" ]
                , div [ class "media-content mr-2 has-text-weight-bold" ] [ text "請求元" ]
                , div [ class "media-content mr-2 has-text-weight-bold" ] [ text "請求量" ]
                , div [ class "media-right mr-2" ] [ text "請求日" ]
                ]
            ]
        ]

receivedClaimView : Claim -> Html Msg
receivedClaimView claim =
    div [ class "card my-3" ]
        [ div [ class "card-content" ]
            [ div [ class "media" ]
                [ div [ class "media-left has-text-weight-bold" ] [ text claim.id ]
                , div [ class "media-content mr-2" ] [ text claim.claimant.name ]
                , div [ class "media-content mr-2" ] [ text (claim.amount ++ claim.unit) ]
                , div [ class "media-right mr-2" ] [ text claim.created_at ]
                ]
            ]
        ]


filterDataWithPage : Int -> List Claim -> List Claim
filterDataWithPage page data =
    toList <| slice (page * 20) (page * 2 + 19) (fromList data)

getMaxPage : List Claim -> Int
getMaxPage data =
    List.length data // 20
