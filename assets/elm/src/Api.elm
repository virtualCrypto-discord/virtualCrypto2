module Api exposing (get,getTask)

import Http
import Json.Decode as Decode
import Task exposing (Task)


get : { a | url : String, token : String, expect : Http.Expect msg } -> Cmd msg
get data =
    Http.request
        { method = "GET"
        , url = data.url
        , headers = [ Http.header "Authorization" ("Bearer " ++ data.token) ]
        , expect = data.expect
        , body = Http.emptyBody
        , timeout = Maybe.Nothing
        , tracker = Maybe.Nothing
        }


jsonResolver : Decode.Decoder a -> Http.Resolver Http.Error a
jsonResolver decoder =
    Http.stringResolver <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ _ body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (Decode.errorToString err))


getTask : { a | token : String, url : String, decoder : Decode.Decoder b } -> Task Http.Error b
getTask data =
    Http.task
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ data.token) ]
        , url = data.url
        , body = Http.emptyBody
        , resolver = jsonResolver data.decoder
        , timeout = Nothing
        }
