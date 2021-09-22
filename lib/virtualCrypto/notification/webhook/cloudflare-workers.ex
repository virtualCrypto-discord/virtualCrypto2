defmodule VirtualCrypto.Notification.Webhook.CloudflareWorkers do
  import Ecto.Query
  alias VirtualCrypto.Repo
  require Logger

  @behaviour VirtualCrypto.Notification.Webhook.Behaviour
  @behaviour VirtualCrypto.Notification.Behaviour

  @spec get_application_webhook_data(VirtualCrypto.User.User.t()) ::
          %{webhook_url: binary(), public_key: binary(), private_key: binary()} | nil
  @event_type_verification 1
  @event_type_claim_status_update 2
  defp get_application_webhook_data(%{application_id: nil}) do
    nil
  end

  defp get_application_webhook_data(%{application_id: id}) do
    q =
      from(applications in VirtualCrypto.Auth.Application,
        select: %{
          webhook_url: applications.webhook_url,
          public_key: applications.public_key,
          private_key: applications.private_key
        },
        where: applications.id == ^id
      )

    Repo.one(q)
  end

  def credentials(config) do
    case Keyword.fetch(config, :ssl) do
      :error -> []
      {:ok, x} -> [ssl: x]
    end
  end

  defp execute_raw(forward, body, timestamp, public_key, private_key) do
    config = Application.get_env(:virtualCrypto, __MODULE__)
    webhook_proxy = Keyword.fetch!(config, :webhook_proxy)
    timestamp = to_string(timestamp)
    message = timestamp <> body

    signature =
      :public_key.sign(
        message,
        :none,
        {:ed_pri, :ed25519, public_key, private_key}
      )

    HTTPoison.post(
      webhook_proxy,
      body,
      %{
        "X-Signature-Ed25519" => Base.encode16(signature, case: :lower),
        "X-Signature-Timestamp" => timestamp,
        "X-Forward" => forward
      },
      credentials(config)
    )
  end

  defp execute_json(user, event) do
    case get_application_webhook_data(user) do
      %{webhook_url: webhook_url, public_key: public_key, private_key: private_key} ->
        execute_raw(
          webhook_url,
          Jason.encode!(event),
          :os.system_time(:second),
          public_key,
          private_key
        )

      _ ->
        :nop
    end
  end

  defp _verify(webhook_url, public_key, private_key) do
    case execute_raw(
           webhook_url,
           Jason.encode!(%{type: @event_type_verification}),
           :os.system_time(:second),
           public_key,
           private_key
         ) do
      {:ok, res} ->
        if res.status_code != 200 do
          Logger.warn("proxy respond with #{res.status_code}")
        end
        case res.headers |> List.keyfind("X-Status", 0) do
          nil ->
            Logger.warn("missing X-Status header: #{res.body}")

            :error

          {_, v} ->
            case Integer.parse(v) do
              {v, ""} ->
                {:ok, v, Jason.decode(res.body)}

              _ ->
                Logger.warn("invalid X-Status header value")

                :error
            end
        end

      {:error, _} ->
        :error
    end
  end

  @impl VirtualCrypto.Notification.Webhook.Behaviour
  def verify(requester, webhook_url, public_key, private_key) do
    requests = [
      fn ->
        case _verify(webhook_url, public_key, private_key) do
          {:ok, 200, {:ok, %{"type" => @event_type_verification}}} -> :ok
          {:ok, _, _} -> :verification_failed
          :error -> :internal_server_error
        end
      end,
      fn ->
        {:ECPrivateKey, 1, private_key, _params, public_key, :asn1_NOVALUE} =
          :public_key.generate_key({:namedCurve, :ed25519})

        case _verify(webhook_url, public_key, private_key) do
          {:ok, 401, _} -> :ok
          {:ok, _, _} -> :verification_failed
          :error -> :internal_server_error
        end
      end
    ]

    with {:short, {:allow, _}} <-
           {:short, Hammer.check_rate("webhook_verification_sec:#{requester}", 3 * 1000, 1)},
         {:middle, {:allow, _}} <-
           {:middle,
            Hammer.check_rate("webhook_verification_hour:#{requester}", 60 * 60 * 1000, 20)},
         {:long, {:allow, _}} <-
           {:long,
            Hammer.check_rate("webhook_verification_day:#{requester}", 24 * 60 * 60 * 1000, 50)} do
      results = requests |> Enum.shuffle() |> Enum.map(& &1.())

      case {:verification_failed in results, :internal_server_error in results,
            results |> Enum.all?(&(&1 == :ok))} do
        {true, _, _} ->
          {:error, :verification_failed}

        {_, true, _} ->
          {:error, :internal_server_error}

        {false, false, true} ->
          :ok

        _ ->
          {:error, :internal_server_error}
      end
    else
      {:short, _} ->
        {:error, {:rate_limit_exceeded, :retry_after_3_seconds}}

      {:middle, _} ->
        {:error, {:rate_limit_exceeded, :retry_after_1_hour}}

      {:long, _} ->
        {:error, {:rate_limit_exceeded, :retry_after_1_day}}
    end
  end

  @impl VirtualCrypto.Notification.Behaviour
  def notify_claim_update(exterior, events) when is_list(events) do
    Task.start(fn ->
      notify_claim_update_sync(exterior, events)
    end)
  end

  def notify_claim_update_sync(exterior, events) when is_list(events) do
    user = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)

    case execute_json(user, %{type: @event_type_claim_status_update, data: events}) do
      {:ok, %{status_code: 200, headers: headers}} ->
        Logger.info(
          "dispatched claim_update: user=#{user.application_id} X-Status=#{headers |> List.keyfind("X-Status", 0) |> elem(1)}"
        )

      {:ok, %{status_code: status_code}} ->
        Logger.info(
          "dispatching claim_update failed: user=#{user.application_id} proxy-status=#{status_code}"
        )

      :nop ->
        nil
    end
  end
end
