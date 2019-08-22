# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :jwk_provider, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:jwk_provider, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

config :jwk_provider, :provider,
  {:system, :atom, "JWK_PROVIDER", :fs}

config :jwk_provider, JwkProvider.FileSystem,
  public_key: {:system, "FS_PUBLIC_KEY", "./priv/certs/trusted_service.crt"},
  private_key: {:system, "FS_PRIVATE_KEY", "./priv/certs/trusted_service.key"}

config :jwk_provider, JwkProvider.Vault,
  url: {:system, "VAULT_URL", "https://localhost:8200"},
  ca_fingerprint: {:system, "VAULT_CA_FINGERPRINT"},
  token: {:system, "VAULT_TOKEN", "myroot"},
  pki_path: {:system, "VAULT_PKI_PATH", "jwt_ca"},
  pki_role: {:system, "VAULT_PKI_ROLE", "trusted_service"},
  common_name: {:system, "VAULT_PKI_CN", "trusted_service"},
  expire_margin: {:system, "VAULT_EXPIRE_MARGIN", 60}
