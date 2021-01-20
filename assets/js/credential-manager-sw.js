import "regenerator-runtime/runtime";
import localforage from "localforage";
localforage.setDriver(localforage.INDEXEDDB);


function onFetchCallbackPage(ev) {
  async function asyncAction(){
    const res = await fetch(ev.request);
    const headers = res.headers;
    const access_token =  headers.get("x-access-token");
    if(!access_token){
      return res;
    }
    await localforage.setItem("access-token",access_token);
    const redirect_to = new URL(headers.get("x-redirect-to") || "/");
    const url = new URL(redirect_to, new URL(ev.request.url).origin);
    return Response.redirect(url,302);
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
  console.log("installed");
});
self.addEventListener("activate", function () {
  console.log("activated");
});
