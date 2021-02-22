module Types.Claim exposing (Claim,Claims,claimsDecoder)

import Json.Decode exposing (Decoder, field, map6, string)
import Types.Currency exposing (Currency, currencyDecoder)
import Types.User exposing (User, userDecoder)


type alias Claim =
    { id : String
    , currency : Currency
    , amount : String
    , claimant : User
    , payer : User
    , created_at : String
    }




type alias Claims =
    List Claim


claimsDecoder : Decoder (List Claim)
claimsDecoder =
    map6 Claim
        (field "id" string)
        (field "currency" currencyDecoder)
        (field "amount" string)
        (field "claimant" userDecoder)
        (field "payer" userDecoder)
        (field "created_at" string)
        |> Json.Decode.list
