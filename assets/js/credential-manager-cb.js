import "regenerator-runtime/runtime";
import localforage from "localforage";

async function main(){
  const tag = document.currentScript;
  await localforage.setItem("access-token",tag.dataset.accessToken);
  document.location.replace(tag.dataset.redirectTo);
}
main().catch(console.error)