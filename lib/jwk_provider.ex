defmodule JwkProvider do
  @moduledoc """
  Documentation for JwkProvider.
  """

  use GenServer

  defmacro __using__(_opts) do
    quote do
      @behaviour JwkProvider
    end
  end

  @callback init(opts :: Keyword.t()) :: {:ok, map()} | {:error, reason :: atom()}

  @provider_lookup %{
    fs: JwkProvider.FileSystem,
    vault: JwkProvider.Vault
  }

  def provider(opts) do
    opts
    |> Keyword.get(:provider, :fs)
    |> (&Map.fetch!(@provider_lookup, &1)).()
  end

  def set_jwk(%{private_jwk: private_jwk, public_jwk: public_jwk}),
    do: GenServer.cast(__MODULE__, {:set_jwk, private_jwk, public_jwk})

  def get_public_jwks(), do: GenServer.call(__MODULE__, :public_jwks)

  def get_private_jwk(), do: GenServer.call(__MODULE__, :private_jwk)

  def get_private_jwk!() do
    {:ok, jwk} = get_private_jwk()
    jwk
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [provider(opts), opts]}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, {provider(opts), opts}, opts)
  end

  def start_link(mod, opts) do
    GenServer.start_link(__MODULE__, {mod, opts}, opts)
  end

  def init({mod, opts}) do
    provider = Keyword.get(opts, :provider, :fs)
    {:ok, mod_state} = mod.init(Keyword.get(opts, provider, []))
    {:ok, %{mod: mod, mod_state: mod_state, public_jwks: [], private_jwk: nil}}
  end

  def handle_call(:public_jwks, _from, %{public_jwks: public_jwks} = state) do
    {:reply, {:ok, %{"keys" => public_jwks}}, state}
  end

  def handle_call(:private_jwk, _from, %{private_jwk: private_jwk} = state) do
    {:reply, {:ok, private_jwk}, state}
  end

  def handle_call(msg, from, %{mod: mod, mod_state: mod_state} = state) do
    case mod.handle_call(msg, from, mod_state) do
      {:reply, reply, mod_state} -> {:reply, reply, %{state | mod_state: mod_state}}
      {:stop, reason, reply, mod_state} -> {:stop, reason, reply, %{state | mod_state: mod_state}}
    end
  end

  def handle_cast({:set_jwk, private_jwk, public_jwk}, %{public_jwks: public_jwks} = state) do
    {:noreply,
     %{
       state
       | public_jwks:
           [public_jwk | public_jwks]
           |> Enum.filter(fn %{"exp" => exp} -> exp > :os.system_time(:seconds) end),
         private_jwk: private_jwk
     }}
  end

  def handle_cast(msg, %{mod: mod, mod_state: mod_state} = state) do
    if function_exported?(mod, :handle_cast, 2) do
      handle_noreply_callback(mod.handle_cast(msg, mod_state), state)
    else
      {:noreply, state}
    end
  end

  def handle_info(msg, %{mod: mod, mod_state: mod_state} = state) do
    if function_exported?(mod, :handle_info, 2) do
      handle_noreply_callback(mod.handle_info(msg, mod_state), state)
    else
      {:noreply, state}
    end
  end

  def handle_noreply_callback({:noreply, mod_state}, state) do
    {:noreply, %{state | mod_state: mod_state}}
  end

  def handle_noreply_callback({:stop, reason, mod_state}, state) do
    {:stop, reason, %{state | mod_state: mod_state}}
  end
end
