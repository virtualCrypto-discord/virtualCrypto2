module Types.User exposing (DiscordUser, User, discordUserDecoder, userDecoder, avatarURL)

import Json.Decode exposing (Decoder, field, map2, map4, string,nullable)


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


avatarURL : User -> String
avatarURL userData =
    case userData.discord.avatar of
        Just a ->
            "https://cdn.discordapp.com/avatars/" ++ userData.discord.id ++ "/" ++ a ++ ".png?size=128"

        Nothing ->
            "https://cdn.discordapp.com/embed/avatars/0.png?size=128"
