#[rustler::nif]
fn hash_bytes(data: rustler::Binary) -> String {
    let hash = blake3::hash(data.as_slice());
    hash.to_hex().to_string()
}

rustler::init!("Elixir.EightDCore.Native");
