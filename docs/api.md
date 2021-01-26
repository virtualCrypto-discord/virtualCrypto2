# Virtual Crypto API

## はじめに
VirtualCrypto APIを用いてVirtual Cryptoと連携するBotやSlash Command、Webアプリケーション、その他様々なものを作成することが可能です。
面白いものを作成していただくことができればこれにまさる喜びはありません。

## Authorization/Authentication
認可/認証には、特に指示がない場合Authorizationヘッダーを使用します。
認証の種類はBearerとし、適切なAccess Tokenを使用してください。

### Types of tokens
#### Access Token
VirtualCryptoが発行するAccess Tokenには三種類あります。
以下に示すものをkind claim、あるいは省略してkindと呼びます。
- user
  - 人間のユーザーに紐づくトークンです。
  - webダッシュボードで使用されています。
  - 将来的にPersonal Access Tokenの仕組みを作成するかもしれません。
- app.user
  - これはアプリケーションに対して発行されるGuildに紐付かないトークンです。
  - 支払いや所持通貨量の確認ができます。
  - 主にclient credentials flowを用いて入手します。
- app.guild
  - これはアプリケーションに対して発行されるGuildが紐付けされたトークンです。
  - giveが可能です。
  - 主にcode flowを用いて入手します。

#### Refresh Token
Access Tokenの有効期限はセキュリティ上短く設定されています。
しかし、それでは毎回、認可をユーザーには求めなければならず不便です。
そこでRefresh Tokenを使用します。
Refresh TokenはトークンエンドポイントにてAccess Tokenと引き換えて使用します。

### OAuth2/OpenID Connect
[OAuth2](https://tools.ietf.org/html/rfc6749)([和訳](https://openid-foundation-japan.github.io/rfc6749.ja.html))/[OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html)([和訳](https://openid-foundation-japan.github.io/openid-connect-core-1_0.ja.html))は認可/認証に関わる、現在、広範に用いられる標準仕様の一つです。
VirtualCyprtoではCode FlowとClient Credentials Flowのみをサポートしています。

#### URLs
| Title                         | URL                 | Specification                                                                            |
| ----------------------------- | ------------------- | ---------------------------------------------------------------------------------------- |
| Authorization Endpoint        | /oauth2/authorize   | The OAuth 2.0 Authorization Framework/OpenID Connect Core 1.0 incorporating errata set 1 |
| Token Endpoint                | /oauth2/token       | The OAuth 2.0 Authorization Framework/OpenID Connect Core 1.0 incorporating errata set 1 |
| Client Registration Endpoint  | /oauth2/clients     | OpenID Connect Dynamic Client Registration 1.0 incorporating errata set 1                |
| Client Configuration Endpoint | /oauth2/clients/@me | OpenID Connect Dynamic Client Registration 1.0 incorporating errata set 1                |
#### Scopes
| Name            | Description                                                                                       |
| --------------- | ------------------------------------------------------------------------------------------------- |
| openid          | OpenID Connect Core 1.0 incorporating errata set 1                                                |
| oauth2.register | use for [OpenID Connect Dynamic Client Registration](#openid_connect_dynamic_client_registration) |
| vc.pay          | allow make payments.                                                                              |
#### OpenID Connect Dynamic Client Registration
VirtualCryptoは[OpenID Connect Dynamic Client Registration](https://openid.net/specs/openid-connect-registration-1_0.html)を実装していますが、
この登録にはkindがuserのAccess Tokenが必要です。

##### POST /oauth2/clients
この操作により、アプリケーション(クライアント)を登録します。

###### Request
Content Typeは`application/json`を用いてください。  
kindが`user`かつ、`oauth2.register`スコープをもつアクセストークンを認証に使用してください。

Parameterは以下のテーブルに示すとおりです。
| Parameter Name                     | Parameter Type        | Parameter Description                                                                                          |
| ---------------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------- |
| redirect_uris                      | String[]              | リダイレクト先のURIの配列(ここで指定されたURIのみがAutorization Endpointのredirect_uriパラメータとして指定可能 |
| grant_types                        | String[],undefined    | `authorization_code`、`refresh_token`、`client_credentials`から選択                                            |
| application_type                   | String,null,undefined | `native`、`web`から選択、デフォルトは`web`                                                                     |
| response_types                     | String[],undefined    | `code`のみサポート                                                                                             |
| client_name                        | String,null,undefined | アプリケーションの名前                                                                                         |
| logo_uri                           | String,null,undefined | アプリケーションのロゴへのURL(ただし、`https`スキームまたは`data`スキームのうちmimeが画像のもののみサポート)   |
| client_uri                         | String,null,undefined | アプリケーションのウェブサイトへのURL(`http`スキームまたは`https`スキームのもののみサポート)                   |
| discord_support_server_invite_slug | String,null,undefined | `https://discord.gg/<invite_slug>`                                                                             |

e.g.
```
  POST /oauth2/clients HTTP/1.1
  Content-Type: application/json
  Accept: application/json
  Host: vcrypto.sumidora.com
  Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.eyJ ...

  {
   "application_type": "web",
   "redirect_uris":
     ["https://client.example.org/callback",
      "https://client.example.org/callback2"],
   "client_name": "My Example",
   "logo_uri": "https://client.example.org/logo.png",
   "discord_support_server_invite_slug": "pcr5GRvQ"
  }
```

###### Response
成功した場合はステータスコード201で以下のパラメータを持つJSONが返却されます。

| Parameter Name            | Parameter Type | Parameter Description                                             |
| ------------------------- | -------------- | ----------------------------------------------------------------- |
| client_id                 | String         | クライアントの識別子。UUID v4。                                   |
| client_secret             | String         | 32byteの乱数をpaddingなしでbase64でエンコードしたもの。           |
| registration_access_token | String         | kindが`app.user`で`oauth2.register`スコープを持ったトークン。     |
| registration_client_uri   | String         | Client Configuration EndpointのURL。                              |
| client_secret_expires_at  | Number         | `client_secret` が期限切れになる時間。期限切れにならないため`0`。 |

e.g.
```
  HTTP/1.1 201 Created
  Content-Type: application/json

  {
   "client_id": "1f7e4e01-3f0d-4375-bbc9-b0abf566ca33",
   "client_secret":
     "Sja7zciWEwFiIxb_vGwDKpBVQqpzPMvAQ1o04cSC8GM",
   "client_secret_expires_at": 0,
   "registration_access_token":
     "this.is.an.access.token.value.ffx83",
   "registration_client_uri":
     "https://vcrypto.sumidora.com/oauth2/clients/@me",
  }
```
###### Error Response
失敗した場合ステータスコード400で以下のパラメータを持つJSONが返却されます。
| Parameter Name    | Parameter Type   | Parameter Description                                                                            |
| ----------------- | ---------------- | ------------------------------------------------------------------------------------------------ |
| error             | String           | `invalid_redirect_uri`,`invalid_client_metadata`。または認証エラーの場合はその他のエラーコード。 |
| error_description | String,undefined | 人間向けの追加のメッセージ。                                                                     |

e.g.
```
  HTTP/1.1 400 Bad Request
  Content-Type: application/json

  {
   "error": "invalid_redirect_uri",
   "error_description": "redirect_uri_scheme_must_be_http_or_https"
  }
```
##### PATCH /oauth2/clients/@me
この操作によって登録内容を操作します。

###### Request
Content Typeは`application/json`を用いてください。  
kindが`app.user`かつ、`oauth2.register`スコープをもつアクセストークンを認証に使用してください。
Bodyには以下のパラメータを持つJSONを指定してください。

| Parameter Name                     | Parameter Type        | Parameter Description                                                                                          |
| ---------------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------- |
| redirect_uris                      | String[],undefined    | リダイレクト先のURIの配列(ここで指定されたURIのみがAutorization Endpointのredirect_uriパラメータとして指定可能 |
| client_secret                      | boolean,undefined     | `true`に設定した場合、client_secretが更新される                                                                |
| grant_types                        | String[],undefined    | `authorization_code`、`refresh_token`、`client_credentials`から選択                                            |
| application_type                   | String,null,undefined | `native`、`web`から選択、デフォルトは`web`                                                                     |
| response_types                     | String[],undefined    | `code`のみサポート                                                                                             |
| client_name                        | String,null,undefined | アプリケーションの名前                                                                                         |
| logo_uri                           | String,null,undefined | アプリケーションのロゴへのURL(ただし、`https`スキームまたは`data`スキームのうちmimeが画像のもののみサポート)   |
| client_uri                         | String,null,undefined | アプリケーションのウェブサイトへのURL(`http`スキームまたは`https`スキームのもののみサポート)                   |
| discord_support_server_invite_slug | String,null,undefined | `https://discord.gg/<invite_slug>`                                                                             |

e.g.
```
  PATCH /oauth2/clients/@me HTTP/1.1
  Content-Type: application/json
  Accept: application/json
  Host: vcrypto.sumidora.com
  Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.eyJ ...

  {
   "discord_support_server_invite_slug": "JtrZyKwu"
  }
```
###### Response
成功時は2xxが返却されます。

e.g.
```
  HTTP/1.1 204 No Content
```

###### Error Response
失敗した場合ステータスコード400で以下のパラメータを持つJSONが返却されます。
| Parameter Name    | Parameter Type   | Parameter Description                                                                            |
| ----------------- | ---------------- | ------------------------------------------------------------------------------------------------ |
| error             | String           | `invalid_redirect_uri`,`invalid_client_metadata`。または認証エラーの場合はその他のエラーコード。 |
| error_description | String,undefined | 人間向けの追加のメッセージ。                                                                     |

e.g.
```
  HTTP/1.1 400 Bad Request
  Content-Type: application/json

  {
   "error": "invalid_redirect_uri",
   "error_description": "redirect_uri_scheme_must_be_http_or_https"
  }
```

##### GET /oauth2/clients/@me
登録内容を確認します。
###### Request
kindが`app.user`かつ、`oauth2.register`スコープをもつアクセストークンを認証に使用してください。
e.g.
```
  GET /oauth2/clients/@me HTTP/1.1
  Accept: application/json
  Host: vcrypto.sumidora.com
  Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.eyJ ...
```
###### Response
ステータスコード200で以下のパラメータを持つJSONが返却されます。
| Parameter Name                     | Parameter Type | Parameter Description                                                                                          |
| ---------------------------------- | -------------- | -------------------------------------------------------------------------------------------------------------- |
| redirect_uris                      | String[]       | リダイレクト先のURIの配列(ここで指定されたURIのみがAutorization Endpointのredirect_uriパラメータとして指定可能 |
| client_id                          | String         | クライアントの識別子。UUID v4。                                                                                |
| client_secret                      | String         | 32byteの乱数をpaddingなしでbase64でエンコードしたもの。                                                        |
| client_secret_expires_at           | Number         | `client_secret` が期限切れになる時間。期限切れにならないため`0`。                                              |
| grant_types                        | String[]       | `authorization_code`、`refresh_token`、`client_credentials`から選択                                            |
| application_type                   | String         | `native`、`web`から選択、デフォルトは`web`                                                                     |
| response_types                     | String[]       | `code`のみサポート                                                                                             |
| client_name                        | String,null    | アプリケーションの名前                                                                                         |
| logo_uri                           | String,null    | アプリケーションのロゴへのURL(ただし、`https`スキームまたは`data`スキームのうちmimeが画像のもののみサポート)   |
| client_uri                         | String,null    | アプリケーションのウェブサイトへのURL(`http`スキームまたは`https`スキームのもののみサポート)                   |
| discord_support_server_invite_slug | String,null    | `https://discord.gg/<invite_slug>`                                                                             |
| discord_user_id                    | String,null    | アプリケーションのdiscordにおけるid                                                                            |
| owner_discord_id                   | String         | アプリケーションのownerのdiscordにおけるid                                                                     |
| user_id                            | String         | VirtualCryptoにおけるアプリケーションのユーザーのid                                                            |

e.g.
```
  HTTP/1.1 200 OK
  Content-Type: application/json

  {
    "application_type": "web",
    "client_id": "6da8804a-4208-468e-a272-84318f7fd9de",
    "client_name": null,
    "client_secret": "46lhhhgs8BkNeXI0mZnJi4jpgHFIqbalek7CPwqxT2w",
    "client_uri": null,
    "discord_support_server_invite_slug": null,
    "discord_user_id": null,
    "grant_types": [],
    "logo_uri": null,
    "owner_discord_id": "408939071289688064",
    "redirect_uris": [],
    "response_types": [],
    "user_id": 3
  }
```
###### Error Response
このリクエストで発生しうるのは認証エラーのみです。

##### GET /oauth2/clients?user=@me
ユーザーのアプリケーションを確認します。
###### Request
kindが`user`かつ、`oauth2.register`スコープをもつアクセストークンを認証に使用してください。
###### Response
`GET /oauth2/clients/@me`のレスポンスの配列が返却されます。

e.g.
```
  GET /oauth2/clients?user=@me HTTP/1.1
  Accept: application/json
  Host: vcrypto.sumidora.com
  Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.eyJ ...

  [
    {
      "client_id": "1f7e4e01-3f0d-4375-bbc9-b0abf566ca33",
      "client_secret":
        "Sja7zciWEwFiIxb_vGwDKpBVQqpzPMvAQ1o04cSC8GM",
      "client_secret_expires_at": 0,
      "application_type": "web",
      "redirect_uris":
        ["https://client.example.org/callback",
          "https://client.example.org/callback2"],
      "client_name": "My Example",
      "logo_uri": "https://client.example.org/logo.png",
      "discord_support_server_invite_slug": "pcr5GRvQ"
      "client_uri": null,
      "owner_discord_id": "212513828641046529"
      ...
    },
    ...
  ]
```

###### Error Response
このリクエストで発生しうるのは認証エラーのみです。