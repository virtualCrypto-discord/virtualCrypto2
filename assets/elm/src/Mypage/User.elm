module Mypage.User exposing (DiscordUser, User, discordUserDecoder, userDecoder)

import Json.Decode exposing (Decoder, field, map2, map3, map4, string,nullable)


type alias DiscordUser =
    { id : String, username : String, avatar : Maybe String, discriminator : String }


type alias User =
    { id : String, discord : DiscordUser }


discordUserDecoder : Decoder DiscordUser
discordUserDecoder =
    map4 DiscordUser
        (field "id" string)
        (field "username" string)
        (field "avatar" (nullable string))
        (field "discriminator" string)



userDecoder : Decoder User
userDecoder =
    map2 User
        (field "id" string)
        (field "discord" discordUserDecoder)
