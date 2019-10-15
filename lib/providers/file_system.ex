defmodule JwkProvider.FileSystem do
  use JwkProvider

  def init(opts) do
    public_path = Keyword.fetch!(opts, :public_key)
    private_path = Keyword.fetch!(opts, :private_key)

    public_jwk =
      public_path
      |> File.read!()
      |> X509.parse_pem()
      |> List.first()
      |> X509.JWK.to_jwk()
      |> Map.put_new("exp", :os.system_time(:seconds) + 31_450_000) # 1 year

    private_jwk =
      private_path
      |> File.read!()
      |> X509.parse_pem()
      |> List.first()
      |> X509.JWK.to_jwk()
      |> (&(Map.merge(public_jwk, &1))).()

    JwkProvider.set_jwk(%{public_jwk: public_jwk, private_jwk: private_jwk})

    {:ok, %{}}
  end
end
