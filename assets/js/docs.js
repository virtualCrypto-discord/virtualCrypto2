import { Elm } from "../elm/src/Docs.elm"
const element = document.getElementById("elm-docs")

Elm.Docs.init({
    node: element,
    flags: element.dataset.raw
})
