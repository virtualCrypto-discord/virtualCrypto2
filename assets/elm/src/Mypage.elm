module Mypage exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Mypage.Dashboard as Dashboard
import Mypage.Claim as Claim

type Route
    = DashboardPage
    | ClaimPage

type alias Model =
    { dashboard : Dashboard.Model
    , claim : Claim.Model
    , accessToken : String
    , route : Route
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
    , claim = Claim.initModel accessToken
    , accessToken = accessToken
    , route = DashboardPage
    }
    , Dashboard.initCmd accessToken |> Cmd.map DashboardMsg
    )


type Msg
    = DashboardMsg Dashboard.Msg
    | ClaimMsg Claim.Msg
    | GoTo Route

changePage : Route -> msg -> Model -> ( Model, Cmd Msg )
changePage route msg model =
    case route of
        DashboardPage ->
            let
                cmd = Dashboard.initCmd model.accessToken
            in
            ( { model | route = DashboardPage }, Cmd.map DashboardMsg cmd)
        ClaimPage ->
            let
                cmd = Claim.initCmd model.accessToken
            in
            ( { model | route = ClaimPage}, Cmd.map ClaimMsg cmd )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DashboardMsg msg_ ->
            let
                ( m_, cmd ) =
                    Dashboard.update msg_ model.dashboard
            in
            ( { model | dashboard = m_ }, Cmd.map DashboardMsg cmd )
        ClaimMsg msg_ ->
            let
                ( m_, cmd ) =
                    Claim.update msg_ model.claim
            in
            ( { model | claim = m_ }, Cmd.map ClaimMsg cmd )
        GoTo route -> changePage route msg model



subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

-- View --


view : Model -> Html Msg
view model =
   div [ class "columns ml-5" ]
           [ sidebar model
           , case model.route of
               DashboardPage -> Dashboard.view model.dashboard |> Html.map DashboardMsg
               ClaimPage -> Claim.view model.claim |> Html.map ClaimMsg
           ]


sidebar : Model -> Html Msg
sidebar model =
    div [ class "column is-one-fifth mt-5", style "border-right" "rgba(192, 192, 192, 0.7) solid 0.5px" ]
        [ aside [ class "menu" ]
            [ ul [ class "menu-list" ]
                [ menuButton "Dashboard" DashboardPage (model.route == DashboardPage)
                , menuButton "請求" ClaimPage (model.route == ClaimPage)
                ]
            , menuLabel "操作"
            , ul [ class "menu-list" ]
                [ li [] [ a [ class "has-text-weight-bold py-3 mt-2 has-text-danger", href "/logout" ] [ text "ログアウト" ] ]
                ]
            ]
        ]

menuButton : String -> Route -> Bool -> Html Msg
menuButton text_ route is_active =
    if is_active
        then li [] [ a [ class "is-active has-text-weight-bold py-3 mt-2", onClick (GoTo route) ] [ text text_ ] ]
        else li [] [ a [ class "has-text-weight-bold py-3 mt-2", onClick (GoTo route) ] [ text text_ ] ]

menuLabel : String -> Html msg
menuLabel text_ =
    p [ class "menu-label" ] [ text text_ ]
