module Mypage.Dashboard exposing (..)
import Array exposing (fromList, slice, toList)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (..)
import Url.Builder exposing (absolute)
import Api

type Status
    = Success
    | Failure

getMaxPage : Balances -> Int
getMaxPage data =
    List.length data // 5

type alias UserData =
    { id : String, name : String, avatar : String, discriminator : String }


type alias Balance =
    { amount : String, asset_status : Int, name : String, unit : String, guild : Int, money_status : Int }


type alias Balances =  List Balance


type alias Model =
    { accessToken : String
    , userData : Maybe UserData
    , userDataStatus : Status
    , balances : Balances
    , balancesStatus : Status
    , page : Int
    }

type Msg
    = GotUserData (Result Http.Error UserData)
    | GotBalances (Result Http.Error Balances)
    | Previous
    | Next

initModel : String -> Model
initModel accessToken =
    { accessToken = accessToken
          , userData = Maybe.Nothing
          , userDataStatus = Success
          , balances = []
          , balancesStatus = Success
          , page = 0
          }

initCmd : String -> Cmd Msg
initCmd accessToken =
    getUserData accessToken

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserData result ->
            case result of
                Ok data ->
                    ( { model | userData = Maybe.Just data }, getBalances model.accessToken)

                Err _ ->
                    ( { model | userDataStatus = Failure }, Cmd.none )

        GotBalances result ->
            case result of
                Ok data ->
                    ( { model | balances = data }, Cmd.none )

                Err _ ->
                    ( { model | balancesStatus = Failure }, Cmd.none )

        Previous ->
            case model.page of
                0 ->
                    ( model, Cmd.none )

                _ ->
                    ( { model | page = model.page - 1 }, Cmd.none )

        Next ->
            if model.page == getMaxPage model.balances then
                ( model, Cmd.none )

            else
                ( { model | page = model.page + 1 }, Cmd.none )

view : Model -> Html Msg
view model =
    div [ class "column" ]
       [ userInfo model
       , div [ class "columns" ]
           [ div [ class "column is-two-fifths" ]
               [ div [ class "has-text-weight-bold is-size-3 ml-2 my-3" ] [ text "所持通貨" ]
               , model.balances |> filterDataWithPage model.page |> List.map balanceView |> div []
               , nav [ class "pagination" ]
                   [ if model.page /= 0 then
                       a [ onClick Previous, class "pagination-previous" ] [ text "前ページ" ]

                     else
                       text ""
                   , if model.page /= getMaxPage model.balances then
                       a [ onClick Next, class "pagination-next" ] [ text "次ページ" ]

                     else
                       text ""
                   ]
               ]
           ]
       ]


avatarURL : UserData -> String
avatarURL userData =
    "https://cdn.discordapp.com/avatars/" ++ userData.id ++ "/" ++ userData.avatar ++ ".png?size=128"


userInfo : Model -> Html msg
userInfo model =
    div [ class "columns" ]
        [ div [ class "column is-2" ]
            [ img [ class "circle", src (Maybe.withDefault "https://cdn.discordapp.com/embed/avatars/0.png?size=128" (Maybe.map avatarURL model.userData)), height 100, width 100 ] []
            ]
        , div [ class "column" ]
            [ div [ class "has-text-weight-bold is-size-3 mt-5" ]
                (Maybe.withDefault []
                    (Maybe.map
                        (\userData -> [ text ("こんにちは、" ++ userData.name ++ "#" ++ userData.discriminator ++ " さん") ])
                        model.userData
                    )
                )
            ]
        ]


filterDataWithPage : Int -> Balances -> Balances
filterDataWithPage page data =
    toList <| slice (page * 5) (page * 5 + 4) (fromList data)

balanceView : Balance -> Html msg
balanceView balance =
    div [ class "card my-3" ]
        [ div [ class "card-content" ]
            [ div [ class "media" ]
                [ div [ class "media-left has-text-weight-bold" ] [ text balance.name ]
                , div [ class "media-content mr-2" ] [ text (balance.amount ++ balance.unit) ]
                ]
            ]
        , footer [ class "card-footer" ]
            [ div [ class "card-footer-item" ] [ text "詳細" ]
            , div [ class "card-footer-item" ] [ text "取引履歴" ]
            , div [ class "card-footer-item" ] [ text "送金" ]
            ]
        ]


getUserData : String -> Cmd Msg
getUserData token =
    Api.get
        { url = absolute [ "api", "v1", "user", "@me" ] []
        , expect = Http.expectJson GotUserData userDataDecoder
        , token = token
        }


getBalances : String -> Cmd Msg
getBalances token =
    Api.get
        { url = absolute [ "api", "v1", "balance", "@me" ] []
        , expect = Http.expectJson GotBalances balancesDecoder
        , token = token
        }


userDataDecoder : Decoder UserData
userDataDecoder =
    map4 UserData
        (field "id" string)
        (field "name" string)
        (field "avatar" string)
        (field "discriminator" string)


balancesDecoder : Decoder Balances
balancesDecoder =
    map6 Balance
        (field "amount" string)
        (field "asset_status" int)
        (field "name" string)
        (field "unit" string)
        (field "guild" int)
        (field "money_status" int)
        |> Json.Decode.list

