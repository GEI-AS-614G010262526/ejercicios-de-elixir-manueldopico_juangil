defmodule Servidor do
  @spec start(integer()) :: {:ok, pid()}
  def start(n) do
  end

  @spec run_batch(pid(), list()) :: list()
  def run_batch(master, jobs) do
  end

  @spec stop(pid()) :: :ok
  def stop(master) do
  end
end

defmodule Worker do
  
end
