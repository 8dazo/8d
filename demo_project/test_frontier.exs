defmodule Test do
  require Record
  Record.defrecordp(:dag_meta, [:key, :value])

  def run do
    r = {:dag_meta, :frontier, ["hash"]}
    case r do
      dag_meta(value: val) -> IO.puts("Matched: #{inspect(val)}")
      _ -> IO.puts("No match")
    end
  end
end
Test.run()
