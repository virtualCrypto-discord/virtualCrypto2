defmodule VirtualCrypto.Auth.Application.Metadata.Validator do
  alias VirtualCrypto.Repo

  def validate_response_types(nil) do
    {:ok, nil}
  end

  @spec validate_response_types(list(String.t())) ::
          nil
          | {:ok, list(String.t())}
          | {:error, {:invalid_client_metadata, :response_types_must_constructed_from_code}}
  def validate_response_types(response_types) do
    response_type_set = MapSet.new(response_types)

    if MapSet.subset?(response_type_set, MapSet.new(["code"])) do
      {:ok, MapSet.to_list(response_type_set)}
    else
      {:error, {:invalid_client_metadata, :response_types_must_constructed_from_code}}
    end
  end

  def validate_grant_types(nil) do
    {:ok, nil}
  end

  def validate_grant_types(grant_types) do
    grant_type_set = MapSet.new(grant_types)

    if MapSet.subset?(grant_type_set, MapSet.new(["authorization_code", "refresh_token"])) do
      {:ok, MapSet.to_list(grant_type_set)}
    else
      {:error,
       {:invalid_client_metadata,
        :grant_types_must_constructed_from_authorization_code_or_refresh_token}}
    end
  end

  def validate_client_uri(nil) do
    {:ok, nil}
  end

  def validate_client_uri(client_uri) do
    parsed_uri = URI.parse(client_uri)

    case parsed_uri.scheme do
      "https" -> {:ok, client_uri}
      "http" -> {:ok, client_uri}
      _ -> {:error, {:invalid_client_metadata, :client_uri_scheme_must_be_http_or_https}}
    end
  end

  def validate_webhook_url(nil) do
    {:ok, nil}
  end

  def validate_webhook_url(webhook_url) do
    parsed_uri = URI.parse(webhook_url)

    case parsed_uri.scheme do
      "https" -> {:ok, webhook_url}
      "http" -> {:ok, webhook_url}
      _ -> {:error, {:invalid_client_metadata, :webhook_url_scheme_must_be_http_or_https}}
    end
  end

  @allowed_media_type [
    "image/bmp",
    "image/vnd.microsoft.icon",
    "image/gif",
    "image/jpeg",
    "image/png",
    "image/svg+xml",
    "image/tiff",
    "image/webp"
  ]
  def validate_logo_uri(nil) do
    {:ok, nil}
  end

  @spec validate_logo_uri(String.t()) ::
          {:ok, String.t()}
          | {:error,
             {:invalid_client_metadata,
              :logo_uri_mime_type_must_be_image
              | :logo_uri_must_not_bigger_than_2048_bytes
              | :logo_uri_scheme_must_be_data_or_https}}
  def validate_logo_uri(icon_uri) do
    url = URL.parse(icon_uri)

    case url.scheme do
      "https" ->
        {:ok, URL.to_string(url)}

      "data" ->
        rebuilt_url = URL.to_string(url)

        case {url.parsed_path.mediatype in @allowed_media_type, byte_size(rebuilt_url) <= 2048} do
          {false, _} ->
            {:error, {:invalid_client_metadata, :logo_uri_mime_type_must_be_image}}

          {_, false} ->
            {:error, {:invalid_client_metadata, :logo_uri_must_not_bigger_than_2048_bytes}}

          _ ->
            {:ok, rebuilt_url}
        end

      _ ->
        {:error, {:invalid_client_metadata, :logo_uri_scheme_must_be_data_or_https}}
    end
  end

  def validate_discord_support_server_invite_slug(nil) do
    {:ok, nil}
  end

  def validate_discord_support_server_invite_slug(slug) do
    if Regex.match?(~r/[0-9a-zA-Z]+/, slug) do
      {:ok, slug}
    else
      {:error,
       {:invalid_client_metadata,
        :discord_support_server_invite_slug_must_construct_from_half_width_alphanumeric}}
    end
  end

  def validate_application_type(application_type) do
    if application_type in ["web", "native"] do
      {:ok, application_type}
    else
      {:error, {:invalid_client_metadata, :application_type_must_be_web_or_native}}
    end
  end

  def verify_webhook_url(_requester, nil, _application_id) do
    :ok
  end

  def verify_webhook_url(requester, webhook_url, application_id) do
    case Repo.get(VirtualCrypto.Auth.Application, application_id) do
      %{webhook_url: ^webhook_url} ->
        :ok

      nil ->
        {:error, {:invalid_client_metadata, :client_not_found}}

      d ->
        case VirtualCrypto.Notification.Webhook.verify(
               requester,
               webhook_url,
               d.public_key,
               d.private_key
             ) do
          :ok ->
            :ok

          {:error, {:rate_limit_exceeded, _}} = x ->
            x

          {:error, :verification_failed} ->
            {:error, {:invalid_client_metadata, :webhook_verification_failed}}

          _ ->
            {:error,
             {:internal_server_error_verifying_webhook, :retry_again_or_contact_developer}}
        end
    end
  end
end
