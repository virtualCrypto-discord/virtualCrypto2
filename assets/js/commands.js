import { Elm } from "../elm/src/Commands.elm"
const element = document.getElementById("elm-commands")

Elm.Commands.init({
    node: element,
    flags: element.dataset.raw
})
