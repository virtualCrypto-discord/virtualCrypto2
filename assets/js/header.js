import { Elm } from "../elm/src/Header.elm"

const element = document.getElementById("elm-header")

Elm.Header.init({
    node: element,
    flags: element.dataset.isLoggedIn === "true"
})
