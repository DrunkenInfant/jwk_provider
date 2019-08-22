defmodule JwkProvider.Vault do
  use JwkProvider

  def init(_) do
    opts = Confex.fetch_env!(:jwk_provider, __MODULE__)

    {:ok, vault} =
      Vault.Conn.init(
        host: Keyword.fetch!(opts, :url),
        ca_fingerprint: {:sha256, Base.decode64!(Keyword.fetch!(opts, :ca_fingerprint))},
        token: Keyword.fetch!(opts, :token)
      )

    issuer_opts =
      opts
      |> Keyword.take([:pki_path, :pki_role, :common_name, :expire_margin])
      |> Keyword.merge(vault: vault, dest: self())

    case Vault.Pki.CertificateIssuer.start_link(issuer_opts) do
      {:ok, pid} ->
        ref = Process.monitor(pid)
        {:ok, %{issuer: %{pid: pid, ref: ref}}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info(
        {:write,
         %Vault.Pki.CertificateSet{certificate: cert, chain: chain, private_key: private_key}},
        state
      ) do
    public_jwk = "#{cert}\n#{chain}" |> X509.Certificate.from_pem() |> X509.JWK.to_jwk()

    private_jwk = private_key |> X509.parse_pem() |> List.first() |> X509.JWK.to_jwk()

    JwkProvider.set_jwk(%{
      public_jwk: public_jwk,
      private_jwk: Map.merge(private_jwk, public_jwk)
    })

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, %{issuer: %{pid: pid, ref: ref}} = state) do
    {:stop, reason, %{state | issuer: nil}}
  end

  def handle_info({:EXIT, _from, reason}, state) do
    {:stop, reason, state}
  end

  def private_key_as_jwk({:rsa_private_key, key}) do
    key
    |> Enum.into(%{}, fn {k, v} -> {to_string(k), X509.JWK.int_to_b64(v)} end)
  end
end
