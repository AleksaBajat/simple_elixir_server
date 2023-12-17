defmodule ElixirServer do
  defmodule Worker do
    require Logger
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def child_spec(opts) do
      %{
        id: ElixirServer.Worker,
        start: {__MODULE__, :start_link, [opts]},
        shutdown: 5_000,
        restart: :permanent,
        type: :worker
       }
    end

    def init([port]) do
      {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])

      Logger.info("Accepting connections at port #{port}")
      loop_acceptor(socket)
    end

    def loop_acceptor(socket) do
      {:ok, client} = :gen_tcp.accept(socket)
      {:ok, pid} = Task.Supervisor.start_child(ElixirServer.TaskSupervisor, fn -> serve(client) end)
      :ok = :gen_tcp.controlling_process(client, pid)
      loop_acceptor(socket)
    end


    defp serve(socket) do
      socket |> recv_packet() |> send_data(socket)
      serve(socket)
    end

    # GET / HTTP/1.1
    defp recv_packet(socket) do
      {:ok, data} = :gen_tcp.recv(socket, 0)
      Logger.info("REQUEST DATA : #{data}")
      lines = TcpReader.get_lines(data)
      Logger.info("LINES DATA : #{lines}")
      request_info = request_info(Enum.at(lines, 0))
      response = case request_info do
        {:get, route, query_params} -> process_get(query_params)
        {:put, route} -> process_put(Enum.at(lines, -1))
        _ -> process_404()
      end

      Logger.info("RESPONSE DATA : #{response}")
      response
    end

    defp request_info(data) do
      case String.split(data, " ")  do
         [method, route, protocol] ->
         case [method, route, protocol] do
            ["GET", route, "HTTP/1.1"] ->
            {route, query_params} = parse_route(route)
            {:get, route, query_params}
            ["PUT", route, "HTTP/1.1"] -> {:put, route}
         end
         _ -> {:error}
      end
    end

    defp parse_route(full_route) do
      case String.split(full_route, "?", parts: 2) do
        [route_only] -> {route_only, nil}
        [route, query_params] -> {route, parse_query_params(query_params)}
        _ -> {:error, "Invalid route format!"}
      end
    end

    defp parse_query_params(query_params) do
      String.split(query_params, "&") |> Enum.reduce(%{}, fn pair, acc ->
        [key, value] = String.split(pair, "=", parts: 2)
        Map.put(acc, key, URI.decode(value))
      end)
    end

    defp process_put(data_line) do
      [key, value] = String.split(data_line, "=")
      KvStorage.put(key, value)
      data = ""
      header = "HTTP/1.1 200 OK\r\n"
      content_type = "Content-Type: text/html; charset=utf-8\r\n"
      content_length = "Content-Length: #{String.length(data)}\r\n\r\n"
      header <> content_type <> content_length <> data
    end

    defp process_get(query_params) do
        data = cond do
        query_params != nil ->
        key = Map.get(query_params, "key")
        Logger.info("Got the key : #{key}")
        data = "Key: #{key}\nValue: #{KvStorage.get(key)}"
        data
        true -> "Hello world from Elixir Server"
      end
      header = "HTTP/1.1 200 OK\r\n"
      content_type = "Content-Type: text/html; charset=utf-8\r\n"
      content_length = "Content-Length: #{String.length(data)}\r\n\r\n"
      header <> content_type <> content_length <> data
    end

    defp process_404() do
      header = "HTTP/1.1 404 Not Found\r\n"
      content_type = "Content-Type: text/html; charset=utf-8\r\n"
      data = "The requested URL was not found on this server."
      content_length = "Content-Length: #{String.length(data)}\r\n\r\n"
      header <> content_type <> content_length <> data
    end

    defp send_data(line, socket) do
      :gen_tcp.send(socket, line)
    end
  end
end
