import { Elm } from "../elm/src/Mypage.elm"

const element = document.getElementById("elm-mypage")

Elm.Mypage.init({
    node: element,
    flags: {}
})
