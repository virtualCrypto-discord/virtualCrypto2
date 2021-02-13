module Mypage.Applications exposing (..)
import Html exposing (..)


type alias Model = {}


type Msg
    = None


initCmd : String -> Cmd Msg
initCmd accessToken = Cmd.none


initModel : String -> Model
initModel _ =
    {}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    (model, Cmd.none)


view : Model -> Html Msg
view model =
    text ""
