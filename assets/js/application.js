import { Elm } from "../elm/src/Application.elm"

const element = document.getElementById("elm-app")
Elm.Application.init({
    node: element,
    flags: JSON.parse(element.dataset.json)
})
