module Mypage exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode exposing (..)
import Array exposing (fromList, slice, toList)

getMaxPage: Balances -> Int
getMaxPage data = (List.length data) // 10

type Status = Success
  | Failure


type alias UserData
  = { id : String, name: String, avatar: String, discriminator: String}

type alias Balance
  = { amount: Int, asset_status: Int, name: String, unit: String, guild: Int, money_status: Int}

type alias Balances
  = List { amount: Int, asset_status: Int, name: String, unit: String, guild: Int, money_status: Int}

type alias Model
  = { userData: UserData, userDataStatus: Status, balances: Balances, balancesStatus: Status, page: Int }

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

view: Model -> Html msg
view model =
  if model.userDataStatus == Failure
    then failureView model
    else div [] [
    userProfileView model
    ]


userProfileView: Model -> Html msg
userProfileView model =
  div [] [
    userAvatar model
    , div [class "has-text-centered is-size-2 mt-3"] [text (model.userData.name ++ "#" ++ model.userData.discriminator)]
    , (filterDataWithPage model.page model.balances) |> List.map balanceView |> balanceTableView
  ]

failureView: Model -> Html msg
failureView model = div [] [text "失敗"]

userAvatar: Model -> Html msg
userAvatar model =
    div [class "has-text-centered"] [img [class "circle mt-5", src ("https://cdn.discordapp.com/avatars/" ++ model.userData.id ++ "/" ++ model.userData.avatar ++ ".png?size=1024")] []]


filterDataWithPage: Int -> Balances -> Balances
filterDataWithPage page data =
    toList <| slice (page*20) (page*10+19) (fromList data)


balanceTableView: (List (Html msg)) -> Html msg
balanceTableView content =
  table [class "table"] [
    thead [] [tr [] [
      th [] [text "通貨名"]
      , th [] [text "単位"]
      , th [] [text "所持数"]
    ]]
    , tbody [] content
  ]

balanceView: Balance -> Html msg
balanceView balance =
  tr [] [
    th [] [text balance.name]
    , td [] [text balance.unit]
    , td [] [text (String.fromInt balance.amount)]
  ]
