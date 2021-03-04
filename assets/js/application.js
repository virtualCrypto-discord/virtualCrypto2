import { Elm } from "../elm/src/Application.elm"

const element = document.getElementById("elm-app")
const app = Elm.Application.init({
    node: element,
    flags: JSON.parse(element.dataset.json)
})

app.ports.copy.subscribe(id => {
    document.querySelector(id).select();
    document.execCommand('copy');
})
