defmodule VirtualCrypto.Auth.InternalAction.Application do
  alias VirtualCrypto.Auth
  alias VirtualCrypto.Repo
  import Ecto.Query
  alias VirtualCrypto.Auth.Application.Metadata.Validator

  defp get_and_compute(req) do
    fn km, validator ->
      case Map.fetch(req, to_string(km)) do
        {:ok, v} ->
          case validator.(v) do
            {:ok, v} -> {:ok, v}
            {:error, _} = err -> err
          end

        :error ->
          {:ok, nil}
      end
    end
  end

  defp fetch(m, k, e) do
    case Map.fetch(m, k) do
      :error -> {:error, e}
      {:ok, v} -> v
    end
  end

  @spec register_client(non_neg_integer(), %{
          optional(:application_type) => String.t(),
          optional(:grant_types) => [String.t()],
          optional(:client_name) => String.t(),
          optional(:client_uri) => String.t(),
          optional(:logo_uri) => String.t(),
          required(:owner_discord_id) => non_neg_integer(),
          optional(:discord_support_server_invite_slug) => String.t(),
          required(:redirect_uris) => [String.t()],
          optional(:webhook_url) => String.t()
        }) :: any()
  def register_client(requester, req) do
    f = get_and_compute(req)

    with {:ok, _response_types} <- f.(:response_types, &Validator.validate_response_types/1),
         {:ok, grant_types} <- f.(:grant_types, &Validator.validate_grant_types/1),
         {:ok, application_type} <-
           f.(:application_type, &Validator.validate_application_type/1),
         {:ok, client_name} <- f.(:client_name, &{:ok, &1}),
         {:ok, client_uri} <- f.(:client_uri, &Validator.validate_client_uri/1),
         {:ok, logo_uri} <- f.(:logo_uri, &Validator.validate_logo_uri/1),
         {:ok, webhook_url} <- f.(:webhook_url, &Validator.validate_webhook_url/1),
         {:ok, discord_support_server_invite_slug} <-
           f.(
             :discord_support_server_invite_slug,
             &Validator.validate_discord_support_server_invite_slug/1
           ),
         redirect_uris when is_list(redirect_uris) <-
           fetch(req, "redirect_uris", {:invalid_redirect_uri, :redirect_uris_must_be_array}),
         {:validate_redirect_uris, true} <-
           {:validate_redirect_uris,
            redirect_uris |> Enum.all?(&(URI.parse(&1).scheme in ["http", "https"]))},
         client_id <- Ecto.UUID.generate(),
         {:ECPrivateKey, 1, private_key, _params, public_key, :asn1_NOVALUE} <-
           :public_key.generate_key({:namedCurve, :ed25519}),
         {:verify_webhook_url, :ok} <-
           {:verify_webhook_url,
            if webhook_url do
              VirtualCrypto.Notification.Webhook.CloudflareWorkers.verify(
                requester,
                webhook_url,
                public_key,
                private_key
              )
            else
              :ok
            end} do
      v = %Auth.Application{
        status: 0,
        client_id: client_id,
        client_secret: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false),
        response_types: [],
        grant_types: grant_types,
        application_type: application_type,
        client_name: client_name,
        client_uri: client_uri,
        logo_uri: logo_uri,
        owner_discord_id: req.owner_discord_id,
        discord_support_server_invite_slug: discord_support_server_invite_slug,
        webhook_url: webhook_url,
        private_key: private_key,
        public_key: public_key
      }

      {:ok, application} = Repo.insert(v)

      Repo.insert_all(
        Auth.RedirectUri,
        redirect_uris
        |> Enum.map(fn redirect_uri ->
          %{
            application_id: application.id,
            redirect_uri: redirect_uri,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }
        end),
        on_conflict: :nothing
      )

      {:ok, %{application: application, redirect_uris: redirect_uris}}
    end
  end

  def get_application_by_client_id_and_verify_secret(client_id, client_secret) do
    v = get_application_by_client_id(client_id)

    case v do
      %Auth.Application{client_secret: ^client_secret} -> {:ok, v}
      %Auth.Application{client_secret: _} -> {:error, {:invalid_client, :invalid_secret}}
      nil -> {:error, {:invalid_client, :not_found_client}}
    end
  end

  def validate_redirect_uri(application_id, redirect_uri) do
    q =
      from u in Auth.RedirectUri,
        where: u.application_id == ^application_id and u.redirect_uri == ^redirect_uri

    Repo.exists?(q)
  end

  def get_application_by_client_id(client_id) do
    case Ecto.UUID.cast(client_id) do
      {:ok, client_id} -> Repo.get_by(Auth.Application, client_id: client_id)
      :error -> nil
    end
  end

  def get_application_and_redirect_uri_by_application_id(application_id) do
    case Repo.get(Auth.Application, application_id) do
      nil ->
        nil

      application ->
        q =
          from redirect_uris in Auth.RedirectUri,
            where: redirect_uris.application_id == ^application_id

        redirect_uris = Repo.all(q)
        %{application: application, redirect_uris: redirect_uris}
    end
  end
end
