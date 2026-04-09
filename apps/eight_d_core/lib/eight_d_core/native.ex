defmodule EightDCore.Native do
  use Rustler, otp_app: :eight_d_core, crate: "eight_d_native"

  # When your NIF is loaded, it will override this function.
  def hash_bytes(_data), do: :erlang.nif_error(:nif_not_loaded)
end
