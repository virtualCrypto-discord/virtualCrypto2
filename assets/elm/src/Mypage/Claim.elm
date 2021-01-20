module Mypage.Claim exposing (..)
import Url.Builder exposing (absolute)
import Api
import Json.Decode exposing (field, Decoder, map2, map6, string, int)
import Array exposing (fromList, slice, toList)
import Http
import Html exposing (..)
import Html.Attributes exposing (..)

type alias User =
    { name : String
    }

type alias Claim =
    { id : String
    , unit : String
    , amount : Int
    , claimant : User
    , payer : User
    , created_at : String
    }

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
        (field "amount" int)
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
    | Previous
    | Next

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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotClaims result ->
            case result of
                Ok data ->
                    ( { model | claims = Just data}, Cmd.none )
                Err _ ->
                    ( model, Cmd.none )
        _ -> ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model.claims of
        Just claim ->
            div [ class "column" ]
                [   div [ class "columns" ]
                        [ div [ class "column is-three-quarters" ]
                            [ title "自分に来た請求"
                            , receivedHeader
                            , claim.received |> List.map receivedClaimView |> div []
                            , title "自分の請求"
                            , sentHeader
                            , claim.sent |> List.map sentClaimView |> div []
                            ]
                        ]
                ]
        Nothing -> div [class "is-size-2"] [text "Loading..."]

title : String -> Html msg
title text_ = div [class "is-size-3 has-text-weight-bold my-5"] [ text text_ ]

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
                , div [ class "media-content mr-2" ] [ text (String.fromInt claim.amount ++ claim.unit) ]
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
                , div [ class "media-content mr-2" ] [ text (String.fromInt claim.amount ++ claim.unit) ]
                , div [ class "media-right mr-2" ] [ text claim.created_at ]
                ]
            ]
        ]


filterDataWithPage : Int -> List Claims -> List Claims
filterDataWithPage page data =
    toList <| slice (page * 5) (page * 5 + 4) (fromList data)
