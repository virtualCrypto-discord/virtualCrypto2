import { Elm } from "../elm/src/Mypage.elm"
import getAccessToken from "./credential-manager-dom";

const element = document.getElementById("elm-mypage");
getAccessToken().then(access_token => {
    Elm.Mypage.init({
        node: element,
        flags: access_token
    })
});