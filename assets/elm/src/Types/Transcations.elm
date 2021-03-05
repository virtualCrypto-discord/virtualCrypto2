module Types.Transcations exposing (..)

import Json.Encode as Encode


transactionsEncoder : String -> String -> String -> Encode.Value
transactionsEncoder unit receiver_discord_id amount =
    Encode.object
    [ ("unit", Encode.string unit)
    , ("receiver_discord_id", Encode.string receiver_discord_id)
    , ("amount", Encode.string amount)
    ]
