defmodule Servidor do
  @spec start(integer()) :: {:ok, pid()}
  # n es el numero de trabajadores
  def start(n) do
    pid = spawn_link(fn -> init(n) end)
    {:ok, pid}
  end

  @spec run_batch(pid(), list()) :: list()
  # el resultado se devuelve cuando todos los trabajos han devuelto su resultado,
  # tiene que estar ordenado
  def run_batch(master, jobs) do
    # validar el trabajo
    send(master, {:trabajos, self(), jobs})

    receive do
      {:resultados, resultados} -> resultados
      {:error, :ocupado} -> {:error, :ocupado}
    end
  end

  @spec stop(pid()) :: :ok
  def stop(master) do
    send(master, {:stop, self()})

    receive do
      :ok -> :ok
    end
  end

  # ==== funciones privadas ====

  defp init(num_workers) do
    workers =
      1..num_workers
      |> Enum.map(fn ->
        spawn(fn -> Worker.loop() end)
      end)

    loop(workers, false)
  end

  defp loop(workers, ocupado) do
    receive do
      # recibe una lista de listas, para cada lista crea un batch
      {:trabajos, from, trabajos} ->
        cod do
          ocupado ->
            send(from, {:error, :ocupado})
            loop(workers, ocupado)

          true ->
            spawn(batch(from, trabajos))
            loop(workers, ocupado)
        end
    end
  end

  # se acuerda del orden y ejecuta los trabajos
  defp batch(from, trabajos) do
    trabajos_with_index = Enum.with_index(trabajos)
    resultados = ejecutar_trabajos(trabajos_with_index, [])

    # TODO recibir resultados y ordenarlos con su index

    send(from, {:resultados, resultados})
  end

  def ejecutar_trabajos(tuplas_trabajos, resultados) do
    #TODO terminar 
    cond do
      length(tuplas_trabajos) == length(resultados) ->
        resultados

      true ->
        send(:work_todo)

        receive do
          {:free, worker_pid} ->
            send(worker_pid, {:trabajo, List.first(tuplas_trabajos)})
            ejecutar_trabajos(List.delete(list, 0), resultados)

          {:occupied} ->
            ejecutar_trabajos(tupla_trabajos, resultados)
        end
    end

    # reservar worker
    # si recibe ok mandar trabajo
  end
end

# defmodule Worker do
#   def loop() do
#     receive do
#       {:trabajo, from, func} ->
#         result = proccess(func)
#         send(from, {:result, self(), result})
#         loop()

#       :stop ->
#         :ok
#     end
#   end

#   def proccess(func) do
#     # trabajar
#   end
# end
