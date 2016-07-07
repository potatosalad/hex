defmodule Hex.Crypto.KeyManager do

  @type t :: %__MODULE__{
    module: module,
    params: any
  }

  defstruct [
    module: nil,
    params: nil
  ]

  @callback init(options :: Keyword.t)                                            :: {:ok, any} | {:error, String.t}
  @callback encrypt(decrypted_key :: binary, params :: any)                       :: binary
  @callback decrypt(encrypted_key :: binary, params :: any)                       :: {:ok, binary} | :error
  @callback encode(params :: any)                                                 :: {String.t, binary}
  @callback decode(algorithm :: String.t, params :: binary, options :: Keyword.t) :: {:ok, any} | :error | {:error, String.t}

  alias Hex.Crypto

  def init(module, options) do
    case module.init(options) do
      {:ok, params} ->
        {:ok, %__MODULE__{module: module, params: params}}
      error ->
        error
    end
  end

  def encrypt(%__MODULE__{module: module, params: params}, decrypted_key) do
    module.encrypt(decrypted_key, params)
  end

  def decrypt(%__MODULE__{module: module, params: params}, encrypted_key) do
    module.decrypt(encrypted_key, params)
  end

  def encode(%__MODULE__{module: module, params: params}) do
    {algorithm, params} = module.encode(params)
    algorithm
    |> Crypto.base64url_encode()
    |> Kernel.<>(".")
    |> Kernel.<>(Crypto.base64url_encode(params))
  end

  def decode(params, options \\ []) do
    case Crypto.base64url_decode(params) do
      {:ok, params} ->
        case String.split(params, ".", parts: 2) do
          [algorithm, params] ->
            case Crypto.base64url_decode(algorithm) do
              {:ok, algorithm} ->
                case Crypto.base64url_decode(params) do
                  {:ok, params} ->
                    algorithm
                    |> case do
                      "A128KW" -> Hex.Crypto.AES_KW
                      "A192KW" -> Hex.Crypto.AES_KW
                      "A256KW" -> Hex.Crypto.AES_KW
                      "PBES2-HS" <> _ -> Hex.Crypto.PBES2_HMAC_SHA2_AES_KW
                      _ -> :error
                    end
                    |> case do
                      :error -> :error
                      module ->
                        case module.decode(algorithm, params, options) do
                          {:ok, params} ->
                            {:ok, %__MODULE__{module: module, params: params}}
                          decode_error ->
                            decode_error
                        end
                    end
                  _ ->
                    :error
                end
              _ -> :error
            end
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

end