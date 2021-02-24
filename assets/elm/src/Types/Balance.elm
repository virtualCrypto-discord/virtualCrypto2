module Types.Balance exposing (..)

import Json.Decode exposing (Decoder, field, map2, string)
import Types.Currency exposing (Currency, currencyDecoder)


type alias Balance =
    { amount : String, currency : Currency }


type alias Balances =
    List Balance


balanceDecoder : Decoder Balance
balanceDecoder =
    map2 Balance
        (field "amount" string)
        (field "currency" currencyDecoder)


balancesDecoder : Decoder Balances
balancesDecoder =
    balanceDecoder |> Json.Decode.list
