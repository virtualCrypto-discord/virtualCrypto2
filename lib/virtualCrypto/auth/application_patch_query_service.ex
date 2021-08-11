defmodule VirtualCrypto.Auth.Application.PatchQuery do
  alias VirtualCrypto.Auth.Application.Metadata.Validator
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Auth
  import Ecto.Query
  import VirtualCrypto.Auth.InternalAction.Util

  defp common2_q(k, q, v, validator) do
    case validator.(v) do
      {:ok, v} -> {:ok, update(q, set: [{^k, ^v}])}
      {:error, _} = err -> err
    end
  end

  defp common2(_k, {:error, _err} = err, _, _) do
    err
  end

  defp common2(k, {:ok, q}, {:ok, v}, validator) do
    common2_q(k, q, v, validator)
  end

  defp common2(k, {:nop, q}, {:ok, v}, validator) do
    common2_q(k, q, v, validator)
  end

  defp common2(_k, x, :error, _validator) do
    x
  end

  defp common(k, q, map, validator) do
    common2(k, q, Map.fetch(map, to_string(k)), validator)
  end

  defp logo_uri(q, map) do
    common(:logo_uri, q, map, &Validator.validate_logo_uri/1)
  end

  def application_type(q, map) do
    common(:application_type, q, map, &Validator.validate_application_type/1)
  end

  defp client_name(q, map) do
    common(:client_name, q, map, &{:ok, &1})
  end

  defp client_uri(q, map) do
    common(:client_uri, q, map, &Validator.validate_client_uri/1)
  end

  defp discord_support_server_invite_slug(q, map) do
    common(
      :discord_support_server_invite_slug,
      q,
      map,
      &Validator.validate_discord_support_server_invite_slug/1
    )
  end

  defp grant_types(q, map) do
    common(:grant_types, q, map, &Validator.validate_grant_types/1)
  end

  defp response_types(q, map) do
    common(:response_types, q, map, &Validator.validate_response_types/1)
  end

  defp client_secret_q(x, q, map) do
    case Map.get(map, "client_secret", false) do
      true -> {:ok, q |> update(set: [client_secret: ^make_secure_random_code()])}
      false -> {x, q}
      _ -> {:error, {:invalid_client_metadata, :client_secret_must_be_boolean_or_not_set}}
    end
  end

  defp client_secret({:ok, q}, map) do
    client_secret_q(:ok, q, map)
  end

  defp client_secret({:nop, q}, map) do
    client_secret_q(:nop, q, map)
  end

  defp client_secret(x, _map) do
    x
  end

  def patch(application_id, params) do
    Repo.transaction(fn ->
      case _patch(application_id, params) do
        {:ok, v} ->
          v

        {:error, v} ->
          Repo.rollback(v)
      end
    end)
  end

  defp _patch(application_id, params) do
    q = Auth.Application
    q = where(q, [app], app.id == ^application_id)

    case {:nop, q}
         |> logo_uri(params)
         |> client_secret(params)
         |> application_type(params)
         |> client_name(params)
         |> client_uri(params)
         |> discord_support_server_invite_slug(params)
         |> grant_types(params)
         |> response_types(params) do
      {:ok, q} ->
        {1, _} = Repo.update_all(q, [])
        patch_redirect_uris(application_id, Map.fetch(params, "redirect_uris"))

      {:nop, _q} ->
        patch_redirect_uris(application_id, Map.fetch(params, "redirect_uris"))

      x ->
        x
    end
  end

  defp patch_redirect_uris(_application_id, :error) do
    {:ok, nil}
  end

  defp patch_redirect_uris(application_id, {:ok, redirect_uris}) do
    if redirect_uris |> Enum.all?(&(URI.parse(&1).scheme in ["http", "https"])) do
      q =
        from redirect_uris in Auth.RedirectUri,
          where: redirect_uris.application_id == ^application_id

      Repo.delete_all(q)

      Repo.insert_all(
        Auth.RedirectUri,
        redirect_uris
        |> Enum.map(fn redirect_uri ->
          %{
            application_id: application_id,
            redirect_uri: redirect_uri,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }
        end),
        on_conflict: :nothing
      )

      {:ok, nil}
    else
      {:error, {:invalid_redirect_uri, :redirect_uri_scheme_must_be_http_or_https}}
    end
  end
end
