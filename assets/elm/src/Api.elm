module Api exposing (get)
import Http

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
