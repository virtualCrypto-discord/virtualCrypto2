import "regenerator-runtime/runtime";
import localforage from "localforage";
import { updateCredential } from "./credential-manager-common";

export default async function getAccessToken() {
  const credential = await localforage.getItem("credential");
  if (credential == null || credential.expires - Date.now() <= 2 * 60 * 1000) {
    const { access_token } = await updateCredential();
    return access_token;
  }
  return credential.access_token;
}
