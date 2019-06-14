defmodule Dockerex.Containers.Logs.Worker do
  use GenServer

  def start_link(pid) do
    GenServer.start_link(__MODULE__, %{pid: pid, ref: nil})
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{id: reference, code: code}, %{pid: pid}) do
    case code do
      200 ->
        {:noreply, %{pid: pid, ref: reference}}

      _ ->
        send(pid, {:error, reference})
        {:stop, :normal, %{pid: pid, ref: reference}}
    end
  end

  def handle_info(%HTTPoison.AsyncHeaders{}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: text}, %{pid: pid, ref: reference}) do
    send(pid, {:ok, reference, text})
    {:noreply, %{pid: pid, ref: reference}}
  end

  def handle_info(%HTTPoison.AsyncEnd{}, %{pid: pid, ref: reference}) do
    send(pid, {:end, reference})
    {:stop, :normal, %{pid: pid, ref: reference}}
  end
end
