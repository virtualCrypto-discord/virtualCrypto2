module Mypage exposing (..)

import Api
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Mypage.Applications as Applications
import Mypage.Claim as Claim
import Mypage.Dashboard as Dashboard
import Mypage.Error as Error
import Mypage.Route exposing (Route(..))
import Task
import Types.User exposing (User, userDecoder)
import Url.Builder exposing (absolute)
import Html


type alias Model =
    { userData : Maybe User
    , claim : Claim.Model
    , dashboard : Dashboard.Model
    , accessToken : String
    , route : Route
    , applications : Applications.Model
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
    case ( Dashboard.init accessToken Maybe.Nothing, Claim.init accessToken Maybe.Nothing, Applications.init accessToken Maybe.Nothing ) of
        ( ( dashboard, dashboardMsg ), ( claim, claimMsg ), ( applications, applicationsMsg ) ) ->
            ( { userData = Maybe.Nothing
              , accessToken = accessToken
              , route = DashboardPage
              , dashboard = dashboard
              , claim = claim
              , applications = applications
              }
            , Cmd.batch [ Cmd.map DashboardMsg dashboardMsg, Cmd.map ClaimMsg claimMsg, Cmd.map ApplicationsMsg applicationsMsg, getUserData accessToken ]
            )


type Msg
    = GotUserData (Result Http.Error User)
    | DashboardMsg Dashboard.Msg
    | ClaimMsg Claim.Msg
    | ApplicationsMsg Applications.Msg
    | GoTo Route


changePage : Route -> Model -> ( Model, Cmd Msg )
changePage route model =
    case route of
        DashboardPage ->
            ( { model | route = DashboardPage }, Cmd.none )

        ClaimPage ->
            ( { model | route = ClaimPage }, Cmd.none )

        ApplicationsPage ->
            ( { model | route = ApplicationsPage }, Cmd.none )

        ErrorPage ->
            ( { model | route = ErrorPage }, Cmd.none )


dispatch : msg -> Cmd msg
dispatch msg =
    Task.succeed msg |> Task.perform identity


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

        ApplicationsMsg msg_ ->
            let
                ( m_, cmd ) =
                    Applications.update msg_ model.applications
            in
            ( { model | applications = m_ }, Cmd.map ApplicationsMsg cmd )

        GoTo route ->
            changePage route model

        GotUserData res ->
            case res of
                Ok userData ->
                    ( { model | userData = Just userData }
                    , Cmd.batch
                        [ Cmd.map ClaimMsg (dispatch (Claim.InjectUserData userData))
                        , Cmd.map DashboardMsg (dispatch (Dashboard.InjectUserdata userData))
                        , Cmd.map ApplicationsMsg (dispatch (Applications.InjectUserData userData))
                        ]
                    )

                Err _ ->
                    ( { model | userData = Nothing }, dispatch (GoTo ErrorPage) )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- View --


view : Model -> Html Msg
view model =
    div [ class "columns ml-5" ]
        [ sidebar model
        , case model.route of
            DashboardPage ->
                Dashboard.view model.dashboard |> Html.map DashboardMsg

            ClaimPage ->
                Claim.view model.claim |> Html.map ClaimMsg

            ApplicationsPage ->
                Applications.view model.applications |> Html.map ApplicationsMsg

            ErrorPage ->
                Error.view 
        ]


sidebar : Model -> Html Msg
sidebar model =
    div [ class "column is-one-fifth mt-5", style "border-right" "rgba(192, 192, 192, 0.7) solid 0.5px" ]
        [ aside [ class "menu" ]
            [ ul [ class "menu-list" ]
                [ menuButton "Dashboard"
                    DashboardPage
                    (case model.route of
                        DashboardPage ->
                            True

                        _ ->
                            False
                    )
                , menuButton "請求"
                    ClaimPage
                    (case model.route of
                        ClaimPage ->
                            True

                        _ ->
                            False
                    )
                ]
            , menuLabel "開発者向け"
            , ul [ class "menu-list" ]
                [ menuButton "アプリケーション" ApplicationsPage (model.route == ApplicationsPage)
                ]
            , menuLabel "操作"
            , ul [ class "menu-list" ]
                [ li [] [ a [ class "has-text-weight-bold py-3 mt-2 has-text-danger", href "/logout" ] [ text "ログアウト" ] ]
                ]
            ]
        ]


menuButton : String -> Route -> Bool -> Html Msg
menuButton text_ route is_active =
    if is_active then
        li [] [ a [ class "is-active has-text-weight-bold py-3 mt-2", onClick (GoTo route) ] [ text text_ ] ]

    else
        li [] [ a [ class "has-text-weight-bold py-3 mt-2", onClick (GoTo route) ] [ text text_ ] ]


menuLabel : String -> Html msg
menuLabel text_ =
    p [ class "menu-label" ] [ text text_ ]


getUserData : String -> Cmd Msg
getUserData token =
    Api.get
        { url = absolute [ "api", "v1", "users", "@me" ] []
        , expect = Http.expectJson GotUserData userDecoder
        , token = token
        }
