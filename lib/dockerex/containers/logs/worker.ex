defmodule Dockerex.Containers.Logs.Worker do
  @moduledoc false

  use GenServer

  def start_link(pid, chunk_decoder) when is_function(chunk_decoder) or chunk_decoder == nil do
    GenServer.start_link(__MODULE__, %{pid: pid, decoder: chunk_decoder || (& &1)})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{id: _reference, code: code}, state) do
    send(state.pid, {:status, code})
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{headers: headers, id: _reference}, state) do
    send(state.pid, {:headers, headers})
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk, id: _reference}, state) do
    send(state.pid, {:chunk, state.decoder.(chunk)})
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncRedirect{headers: _headers, id: _reference, to: to}, state) do
    send(state.pid, {:redirect, to})
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: _reference}, state) do
    send(state.pid, :end)
    {:stop, :normal, state}
  end
end
