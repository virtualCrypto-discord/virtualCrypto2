const localforage = require("localforage");
import "regenerator-runtime/runtime";

export default async function getAccessToken() {
  return await localforage.getItem("access-token");
}
