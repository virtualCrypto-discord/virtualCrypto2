import { Elm } from "../elm/src/Header.elm"

const element = document.getElementById("elm-header")
Elm.Header.init({
    node: element,
    flags: "isLoggedIn" in element.dataset
})
