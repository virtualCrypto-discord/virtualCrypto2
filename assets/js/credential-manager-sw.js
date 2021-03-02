import "regenerator-runtime/runtime";
import localforage from "localforage";
localforage.setDriver(localforage.INDEXEDDB);


function onFetchCallbackPage(ev) {
  async function asyncAction() {
    const res = await fetch(ev.request.url);
    const headers = res.headers;
    const access_token = headers.get("x-access-token");
    const expires_in = headers.get("x-expires-in");

    if (!access_token || !expires_in) {
      return res;
    }
    await localforage.setItem("credential", { access_token, expires: Date.now() + Number(expires_in) * 1000 });
    const redirect_to = new URL(headers.get("x-redirect-to") || "/");
    const url = new URL(redirect_to, new URL(ev.request.url).origin);
    return Response.redirect(url, 302);
  }
  ev.respondWith(asyncAction());
}
/**
* 
* @param {FetchEvent} ev 
*/
function onFetch(ev) {
  const req = ev.request;
  if (req.method !== "GET") {
    return;
  }
  const requestUrl = new URL(req.url);

  const pathname = requestUrl.pathname;
  switch (pathname) {
    case "/callback/discord":
      onFetchCallbackPage(ev);
      break;
    default:
      return;
  }
}

self.addEventListener("fetch", (ev) => {
  onFetch(ev);
});
self.addEventListener("install", (ev) => {
  self.skipWaiting();
  console.log("installed");
});
self.addEventListener("activate", (ev) => {
  console.log("activated");
});
