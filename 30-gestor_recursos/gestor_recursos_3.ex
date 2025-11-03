##3.Tolerante a fallos
defmodule Servidor do

  ##start del servidor
def start(recursos) do
  pid = spawn(fn -> init(recursos) end)
  :global.register_name(:gestor, pid)
 ## IO.puts("Gestor iniciado y registrado globalmente en #{node()}")
  :ok
end

defp init(recursos) do
  Process.flag(:trap_exit, true)
  loop(recursos, %{})
end


  ##bucle que recibe mensajes
  defp loop(disponibles, asignados) do
    receive do

      {:alloc, from} -> case disponibles do
        [recurso|resto] ->
          ##linkeamos
          Process.link(from)

          nodo_cliente = node(from)
            if nodo_cliente != node() do
              Node.monitor(nodo_cliente, true)
            end

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

     {:EXIT, pid, reason} ->

          #????Cambiar esto
          recursos_perdidos =
          Enum.filter(asignados, fn {_r, p} -> p == pid end)
          |> Enum.map(fn {r, _} -> r end)

          ##Borrarlo luego
          if recursos_perdidos != [] do
          IO.puts("Cliente #{inspect(pid)} murió (#{inspect(reason)}), liberando #{inspect recursos_perdidos}")
          end
          ##

          nuevo_asignados = Map.drop(asignados, recursos_perdidos)
          nuevo_disponibles = recursos_perdidos ++ disponibles

          loop(nuevo_disponibles, nuevo_asignados)

      ## manejar la caída de un nodo remoto
      {:nodedown, nodo} ->
        recursos_perdidos =
          asignados
          |> Enum.filter(fn {_r, p} -> node(p) == nodo end) #nos quedamos solo con las entradas donde el PID pertenece al nodo caído.
          |> Enum.map(fn {r, _} -> r end)

        if recursos_perdidos != [] do
          IO.puts("Nodo #{inspect(nodo)} cayó, libera#{inspect(recursos_perdidos)}")
        end

        nuevo_asignados = Map.drop(asignados, recursos_perdidos)
        nuevo_disponibles = recursos_perdidos ++ disponibles

        loop(nuevo_disponibles, nuevo_asignados)
    end
  end


def alloc() do
  case :global.whereis_name(:gestor) do
    :undefined ->
      {:error, :gestor_no_disponible}

    pid ->
      send(pid, {:alloc, self()})
      receive do
        respuesta -> respuesta
      end
  end
end

def release(recurso) do
  case :global.whereis_name(:gestor) do
    :undefined ->
      {:error, :gestor_no_disponible}

    pid ->
      send(pid, {:release, self(), recurso})
      receive do
        respuesta -> respuesta
      end
  end
end

def avail() do
  case :global.whereis_name(:gestor) do
    :undefined ->
      {:error, :gestor_no_disponible}

    pid ->
      send(pid, {:avail, self()})
      receive do
        num -> num
      end
  end
end

  ##Para la versión 2 --> link(¿?) cambiar configuracion con trap.exist --> este se murio
  ##Para la versión 3 --> nodos

end
