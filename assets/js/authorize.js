import { Elm } from "../elm/src/Authorize.elm"

const element = document.getElementById("elm-authorize")
const d = element.dataset;
Elm.Authorize.init({
  node: element,
  flags: {
    redirect_uri: d.redirectUri, state: d.state||null, scope: d.scope, client_id: d.clientId, csrf_token: d.csrfToken,response_type: d.responseType,guild_id: d.guildId
  }
})
