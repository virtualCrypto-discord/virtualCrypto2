import localforage from "localforage";

export async function updateCredential() {
  const data = await fetch("/token", {
    method: "post",
    credentials: "same-origin"
  }).then(res => res.json());
  const expires = Date.now() + data.expires_in * 1000;
  await localforage.setItem("credential", {
    access_token: data.access_token,
    expires,
  });
  return { ...data, expires };
}