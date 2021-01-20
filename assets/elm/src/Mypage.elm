module Mypage exposing (..)

import Array exposing (fromList, slice, toList)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (..)
import Url.Builder exposing (absolute)
import Mypage.Dashboard as Dashboard



type alias Model =
    { dashboard : Dashboard.Model
    , accessToken: String
    }


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : String -> ( Model, Cmd Msg )
init accessToken =
    (
    { dashboard = Dashboard.initModel accessToken
    , accessToken = accessToken
    }
    , Dashboard.getUserData accessToken |> Cmd.map DashboardMsg
    )


type Msg
    = DashboardMsg Dashboard.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DashboardMsg msg_ ->
            let
                ( m_, cmd ) =
                    Dashboard.update msg_ model.dashboard
            in
            ( { model | dashboard = m_ }, Cmd.map DashboardMsg cmd )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

-- View --


view : Model -> Html Msg
view model =
   div [ class "columns ml-5" ]
           [ sidebar model
           , Dashboard.view model.dashboard |> Html.map DashboardMsg
           ]


sidebar : Model -> Html Msg
sidebar model =
    div [ class "column is-one-fifth mt-5", style "border-right" "rgba(192, 192, 192, 0.7) solid 0.5px" ]
                [ aside [ class "menu" ]
                    [ ul [ class "menu-list" ]
                        [ li [] [ a [ class "is-active has-text-weight-bold py-3 mt-2" ] [ text "Dashboard" ] ]
                        ]
                    , menuLabel "操作"
                    , ul [ class "menu-list" ]
                        [ li [] [ a [ class "has-text-weight-bold py-3 mt-2 has-text-danger", href "/logout" ] [ text "ログアウト" ] ]
                        ]
                    ]
                ]


menuLabel : String -> Html msg
menuLabel text_ =
    p [ class "menu-label" ] [ text text_ ]
