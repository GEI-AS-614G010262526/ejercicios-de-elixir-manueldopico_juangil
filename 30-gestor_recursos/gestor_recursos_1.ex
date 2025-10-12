##1. No distribuido
defmodule Servidor do

  ##start del servidor
  def start(recursos) do
    pid = spawn(fn -> loop(recursos, %{}) end)
    Process.register(pid, :gestor)
    :ok
  end

  ##bucle que recibe mensajes
  defp loop(disponibles, asignados) do
    receive do

      {:alloc, from} -> case disponibles do
        [recurso|resto] ->
          send(from,{:ok,recurso})
          ##guarda en el mapa asignados que el recurso recurso ahora pertenece al cliente con pid from
          nuevo_asignados = Map.put(asignados, recurso, from)
          loop(resto, nuevo_asignados)

        [] ->
          send(from,{:error, :sin_recursos})
          loop(disponibles, asignados)
      end

      {:release,from,recurso}-> case Map.get(asignados, recurso) do
        from ->
          nuevo_asignados = Map.delete(asignados, recurso)
          send(from, :ok)
          loop([recurso|disponibles],nuevo_asignados)

        nil ->
          send(from, {:error, :recurso_no_reservado})
          loop(disponibles, asignados)

        _else ->
        send(from, {:error, :recurso_no_reservado})
        loop(disponibles, asignados)
      end

      {:avail, from} ->
        send(from, length(disponibles))
        loop(disponibles, asignados)
    end
  end


  def alloc() do
    send(:gestor, {:alloc, self()})
    receive do
      respuesta -> respuesta
    end
  end

  def release(recurso) do
    send(:gestor, {:release, self(), recurso})
    receive do
      respuesta -> respuesta
    end
  end

def avail() do
    send(:gestor, {:avail, self()})
    receive do
      num -> num
    end
  end


  ##Para la versión 2 --> link(¿?) cambiar configuracion con trap.exist --> este se murio
  ##Para la versión 3 --> nodos

end
