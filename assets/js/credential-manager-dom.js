import "regenerator-runtime/runtime";
import localforage from "localforage";

export default async function getAccessToken() {
  const credential = await localforage.getItem("credential");
  if (credential == null || credential.expires - Date.now() <= 5 * 60 * 1000) {
    const data = await fetch("/token", {
      method: "post",
      credentials: "same-origin"
    }).then(res => res.json())
    await localforage.setItem("credential", {
      access_token: data.access_token,
      expires: Date.now() + data.expires_in * 1000
    });
    return data.access_token;
  }
  return credential.access_token;
}
