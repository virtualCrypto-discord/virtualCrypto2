import { Elm } from "../elm/src/Header.elm"

const element = document.getElementById("elm-header")

Elm.Header.init({
    node: element,
    flags: {
        is_login: element.dataset.isLogin === "true",
        name: element.dataset.userName,
        id: element.dataset.userId,
        avatar: element.dataset.userAvatar }
})
