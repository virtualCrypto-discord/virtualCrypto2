defmodule VirtualCrypto.Guardian do
  use Guardian, otp_app: :virtualCrypto
  @impl Guardian
  def subject_for_token(resource, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = to_string(resource.id)
    {:ok, sub}
  end

  @impl Guardian
  def resource_from_claims(claims) do
    scopes = Map.get(claims, "scopes", [])

    {
      :ok,
      %{
        "sub" => claims["sub"],
        "oauth2.register" => "oauth2.register" in scopes,
        "kind" => claims["kind"]
      }
    }
  end

  def issue_token_for_user(id, scopes) when is_list(scopes) do
    encode_and_sign(%{id: id}, %{scopes: scopes, kind: "user"})
  end

  def issue_token_for_app_user(id, scopes) when is_list(scopes) do
    encode_and_sign(%{id: id}, %{scopes: scopes, kind: "app.user"})
  end
end
