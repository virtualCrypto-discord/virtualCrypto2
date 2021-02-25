module Types.Applications exposing (..)
import Json.Decode exposing (field, Decoder, string, int, succeed, list, andThen, fail, nullable)
import Json.Decode.Extra exposing (andMap)
import Dict

type GrantType =
      AuthorizationCode
    | RefreshToken
    | ClientCredentials

type ResponseType =
    Code

type alias Application =
    { redirect_uris : List String
    , client_id : String
    , client_secret : String
    , client_secret_expires_at : Int
    , grant_types : List GrantType
    , application_type : String
    , response_types : List ResponseType
    , client_name : Maybe String
    , logo_uri : Maybe String
    , client_uri : Maybe String
    , discord_support_server_invite_slug : Maybe String
    , discord_user_id : Maybe String
    , owner_discord_id : String
    , user_id : String
    }

type alias Applications = List Application

grantTypeDecoder : Decoder GrantType
grantTypeDecoder =
    string
        |> andThen (\str ->
            case str of
                "authorization_code" -> succeed AuthorizationCode
                "refresh_token" -> succeed RefreshToken
                "client_credentials" -> succeed ClientCredentials
                _ -> fail "unknown type"
        )

grantTypesDecoder : Decoder (List GrantType)
grantTypesDecoder =
    list grantTypeDecoder

responseTypeDecoder : Decoder ResponseType
responseTypeDecoder =
    string
        |> andThen (\str ->
            case str of
                "code" -> succeed Code
                _ -> fail "unknown type"
        )

responseTypesDecoder : Decoder (List ResponseType)
responseTypesDecoder =
    list responseTypeDecoder


applicationDecoder : Decoder Application
applicationDecoder =
    succeed Application
        |> andMap (field "redirect_uris" (list string))
        |> andMap (field "client_id" string)
        |> andMap (field "client_secret" string)
        |> andMap (field "client_secret_expires_at" int)
        |> andMap (field "grant_types" grantTypesDecoder)
        |> andMap (field "application_type" string)
        |> andMap (field "response_types" responseTypesDecoder)
        |> andMap (field "client_name" (nullable string))
        |> andMap (field "logo_uri" (nullable string))
        |> andMap (field "client_uri" (nullable string))
        |> andMap (field "discord_support_server_invite_slug" (nullable string))
        |> andMap (field "discord_user_id" (nullable string))
        |> andMap (field "owner_discord_id" string)
        |> andMap (field "user_id" string)

applicationsDecoder : Decoder Applications
applicationsDecoder =
    applicationDecoder |> Json.Decode.list
