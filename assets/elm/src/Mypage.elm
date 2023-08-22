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
import Types.User exposing (User, userDecoder, avatarURL)
import Url.Builder exposing (absolute)
import Html
import Svg
import Svg.Attributes as SvgA


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
    div [class "dashboard"]
        [ sidebar model
        , case model.route of
            DashboardPage -> Dashboard.view model.dashboard |> Html.map DashboardMsg
            ClaimPage -> Claim.view model.claim |> Html.map ClaimMsg
            ApplicationsPage -> Applications.view model.applications |> Html.map ApplicationsMsg
            ErrorPage -> Error.view
        ]


sidebar : Model -> Html Msg
sidebar model =
    div [class "sidebar"]
        [ div [class "sidebar-content"]
            [ userView model
            , sidebarButton model "Dashboard" DashboardPage
            , sidebarButton model "請求" ClaimPage
            , sidebarButton model "通貨" ClaimPage
            , sidebarButton model "アプリケーション" ClaimPage
            , sidebarButton model "設定" ClaimPage
            ]
        ]


getUserData : String -> Cmd Msg
getUserData token =
    Api.get
        { url = absolute [ "api", "v2", "users", "@me" ] []
        , expect = Http.expectJson GotUserData userDecoder
        , token = token
        }


userView : Model -> Html Msg
userView model =
    case model.userData of
        Just data ->
            div [class "sidebar-userinfo"]
                [ figure [class "image is-128x128 sidebar-avatar"]
                    [ img [class "is-rounded", src <| avatarURL data] []
                    ]
                , p [class "has-text-weight-bold normal-text has-text-centered is-size-4 mb-5"] [text <| data.discord.username ++ "#" ++ data.discord.discriminator]
                ]
        _ ->
            div [class "sidebar-userinfo"]
                [ figure [class "image is-128x128 sidebar-avatar"]
                    [ img [class "is-rounded", src "https://cdn.discordapp.com/embed/avatars/0.png?size=128"] []
                    ]
                , div []
                    [ Svg.svg [SvgA.width "330", SvgA.height "50", SvgA.viewBox "0 0 330 50"]
                        [ Svg.rect
                            [ SvgA.x "35"
                            , SvgA.y "0"
                            , SvgA.width "200"
                            , SvgA.height "30"
                            , SvgA.rx "15"
                            , SvgA.ry "15"
                            , SvgA.fill "gray"
                            ] []
                        ]
                    ]

                ]


sidebarButton : Model -> String -> Route -> Html Msg
sidebarButton model text_ page =
    button [class (if model.route == page then "sidebar-button" else "sidebar-button-not-selected"), onClick (GoTo page)]
        [ span [class (if model.route == page then "sidebar-button-text" else "sidebar-button-text-not-selected")] [text text_]
        ]
