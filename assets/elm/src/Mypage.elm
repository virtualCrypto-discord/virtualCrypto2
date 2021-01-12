module Mypage exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (..)
import Array exposing (fromList, slice, toList)

getMaxPage: Balances -> Int
getMaxPage data = (List.length data) // 5

type Status = Success
  | Failure


type alias UserData
  = { id : String, name: String, avatar: String, discriminator: String}

type alias Balance
  = { amount: Int, asset_status: Int, name: String, unit: String, guild: Int, money_status: Int}

type alias Balances
  = List { amount: Int, asset_status: Int, name: String, unit: String, guild: Int, money_status: Int}

type alias Model
  = { userData: UserData,
      userDataStatus: Status,
      balances: Balances,
      balancesStatus: Status,
      page: Int
  }

main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init: () -> ( Model, Cmd Msg )
init _ = (
  { userData = { id = "", name = "", avatar = "", discriminator = ""}
    , userDataStatus = Success
    , balances = []
    , balancesStatus = Success
    , page = 0
  }
  , getUserData
  )

type Msg = GotUserData (Result Http.Error UserData)
  | GotBalances (Result Http.Error Balances)
  | Previous
  | Next

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GotUserData result ->
      case result of
        Ok data -> ( { model | userData = data }, getBalances )
        Err _ -> ( { model | userDataStatus = Failure }, Cmd.none )
    GotBalances result ->
      case result of
        Ok data -> ( { model | balances = data }, Cmd.none )
        Err _ -> ( { model | balancesStatus = Failure }, Cmd.none )
    Previous ->
      case model.page of
        0 -> (model, Cmd.none)
        _ -> ( { model | page = model.page - 1 }, Cmd.none )
    Next ->
      if model.page == getMaxPage(model.balances)
      then (model, Cmd.none)
      else ( { model | page = model.page + 1 }, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

getUserData : Cmd Msg
getUserData =
  Http.get
    { url = "http://localhost/api/v1/user/@me"
    , expect = Http.expectJson GotUserData userDataDecoder
    }

getBalances : Cmd Msg
getBalances =
  Http.get
    { url = "http://localhost/api/v1/balance/@me"
    , expect = Http.expectJson GotBalances balancesDecoder
    }

userDataDecoder : Decoder UserData
userDataDecoder =
  map4 UserData
    (field "id" string)
    (field "name" string)
    (field "avatar" string)
    (field "discriminator" string)


balancesDecoder : Decoder Balances
balancesDecoder
  = map6 Balance
    (field "amount" int)
    (field "asset_status" int)
    (field "name" string)
    (field "unit" string)
    (field "guild" int)
    (field "money_status" int)
    |> Json.Decode.list


-- View --

view: Model -> Html Msg
view model =
  if model.userDataStatus == Failure
    then failureView model
    else div [] [
    userProfileView model
    ]


userProfileView: Model -> Html Msg
userProfileView model =
  div [class "columns ml-5"] [
    div [class "column is-one-fifth mt-5", style "border-right" "rgba(192, 192, 192, 0.7) solid 0.5px"] [
      aside [class "menu"] [
        ul [class "menu-list"] [
          li [] [a [class "is-active has-text-weight-bold py-3 mt-2"] [text "Dashboard"]]
        ]
      --, menuLabel "ウォレット"
      --, ul [class "menu-list"] [
      --    li [] [a [class "has-text-weight-bold py-3 mt-2"] [text "所持通貨"]]
      --  , li [] [a [class "has-text-weight-bold py-3 mt-2"] [text "取引履歴"]]
      --  ]
      ]
    ]
  , div [class "column"] [
      userInfo model
    , div [class "columns"] [
      div [class "column is-two-fifths"] [
        div [class "has-text-weight-bold is-size-3 ml-2 my-3"] [text "所持通貨"]
      , model.balances |> filterDataWithPage model.page |> List.map balanceView |> div []
      , nav [class "pagination"] [
          a [ onClick Previous, class "pagination-previous" ] [ text "前ページ" ]
        , a [ onClick Next, class "pagination-next" ] [ text "次ページ" ]
        ]
      ]
    ]
    ]
  ]

failureView: Model -> Html msg
failureView model = div [] [text "失敗"]

userInfo: Model -> Html msg
userInfo model =
    div [class "columns"] [
      div [class "column is-2"] [
        img [class "circle", src ("https://cdn.discordapp.com/avatars/" ++ model.userData.id ++ "/" ++ model.userData.avatar ++ ".png?size=1024"), height 100, width 100] []]
    , div [class "column"] [
      div [class "has-text-weight-bold is-size-3 mt-5"] [text ("こんにちは、" ++ model.userData.name ++ "#" ++ model.userData.discriminator ++ " さん")]
      ]
    ]

filterDataWithPage: Int -> Balances -> Balances
filterDataWithPage page data =
    toList <| slice (page*5) (page*5+4) (fromList data)

menuLabel: String -> Html msg
menuLabel text_ = p [class "menu-label"] [text text_]


balanceView: Balance -> Html msg
balanceView balance =
  div [class "card my-3"] [
    div [class "card-content"] [
      div [class "media"] [
        div [class "media-left has-text-weight-bold"] [text balance.name]
      , div [class "media-content mr-2"] [text ((String.fromInt balance.amount) ++ balance.unit)]
      ]
    ]
  , footer [class "card-footer"] [
      div [class "card-footer-item"] [text "詳細"]
    , div [class "card-footer-item"] [text "取引履歴"]
    , div [class "card-footer-item"] [text "送金"]
    ]
  ]
