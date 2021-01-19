import "regenerator-runtime/runtime";
import localforage from "localforage";

export default async function getAccessToken() {
  return await localforage.getItem("access-token");
}
