import "regenerator-runtime/runtime";
import localforage from "localforage";

async function main() {
  const tag = document.currentScript;

  await localforage.setItem("credential", {
    access_token: tag.dataset.accessToken,
    expires: Date.now() + tag.dataset.expiresIn * 1000
  });

  document.location.replace(tag.dataset.redirectTo);
}
main().catch(console.error)
