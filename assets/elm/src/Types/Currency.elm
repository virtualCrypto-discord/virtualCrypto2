module Types.Currency exposing (Currency,currencyDecoder)
import Json.Decode exposing(field,string)
type alias Currency =
    { unit : String, name : String }

currencyDecoder : Json.Decode.Decoder Currency
currencyDecoder =
    Json.Decode.map2 Currency (field "unit" string)  (field "name" string)
