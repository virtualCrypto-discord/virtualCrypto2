import localforage from "localforage";
import "regenerator-runtime/runtime";
localforage.setDriver(localforage.INDEXEDDB);


function onFetchCallbackPage(ev) {
  async function asyncAction(){
    const res = await fetch(ev.request);
    const headers = res.headers;
    await localforage.setItem("access-token", headers.get("x-access-token"));
    const url = new URL(headers.get("x-redirect-to") || "/", new URL(ev.request.url).origin);
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
  ev.waitUntil(self.skipWaiting());
});
self.addEventListener("activate", function (ev) {
  console.log("activated");
  ev.waitUntil(clients.claim());
});
