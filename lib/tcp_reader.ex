defmodule TcpReader do
  def get_lines(raw_packet) do
    lines = String.split(raw_packet, "\n")
    Enum.map(lines, fn line -> line |> String.replace("\r", "") end)
  end
end
