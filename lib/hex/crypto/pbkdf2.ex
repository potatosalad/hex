defmodule Hex.Crypto.Pbkdf2 do
  use Bitwise

  @max_length (1 <<< 32) - 1
  @salt_range 16..1024

  def pbkdf2(pass, salt, iterations, length, hash)
  when iterations > 0 and length < @max_length and byte_size(salt) in @salt_range,
    do: pbkdf2(pass, salt, iterations, length, hash, 1, [], 0)

  defp pbkdf2(pass, salt, iterations, max_length, hash, block_ix, acc, length)
  when length < max_length do
    pseudo = :crypto.hmac(hash, pass, <<salt::binary, block_ix::32>>)
    block = iterate(pass, hash, iterations-1, pseudo, pseudo)
    pbkdf2(pass, salt, iterations, max_length, hash, block_ix+1, [acc|block], length+byte_size(block))
  end
  defp pbkdf2(_pass, _salt, _iterations, max_length, _hash, _block_ix, acc, _length) do
    <<result::binary-size(max_length), _::binary>> = IO.iodata_to_binary(acc)
    result
  end

  defp iterate(_pass, _hash, 0, _prev, acc), do: acc
  defp iterate(pass, hash, iteration, prev, acc) do
    next = :crypto.hmac(hash, pass, prev)
    iterate(pass, hash, iteration-1, next, :crypto.exor(next, acc))
  end
end
