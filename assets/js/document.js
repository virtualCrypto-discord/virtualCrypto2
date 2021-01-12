import { Elm } from "../elm/src/Document.elm"

const element = document.getElementById("elm-document")

Elm.Document.init({
    node: element,
    flags: {}
})
