defmodule Servidor do
  @spec start(integer()) :: {:ok, pid()}
  # n es el numero de trabajadores
  def start(n) do
    pid = spawn_link(fn -> init(n) end)
    {:ok, pid}
  end

  @spec run_batch(pid(), list()) :: list()
  # gestiona un lote de trabajos, devolviendo error si aun no ha terminado
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

  # funcion que crea la cantidad de trabajadores deseada
  defp init(num_workers) do
    workers =
      1..num_workers
      |> Enum.map(fn _ ->
        spawn(fn -> Worker.loop() end)
      end)

    loop(workers, false)
  end

  defp loop(workers, ocupado) do
    receive do
      # para cada trabajo crea un batch
      {:trabajos, from, trabajos} ->
        cond do
          # si ya hay un trabajo en proceso no acepta el trabajo
          ocupado ->
            send(from, {:error, :ocupado})
            loop(workers, ocupado)

          # si esta libre crea un proceso para el trabajo
          true ->
            parent = self()
            spawn(fn -> batch(parent, from, workers, trabajos) end)
            loop(workers, true)
        end

      :batch_done ->
        loop(workers, false)

      {:stop, from} ->
        Enum.each(workers, fn w -> send(w, :stop) end)
        send(from, :ok)
    end
  end

  # se acuerda del orden con un index y ejecuta los trabajos
  # ordena el resultado y lo envia
  defp batch(parent, from, workers, trabajos) do
    # se crean tuplas con el trabajo y un index
    trabajos_with_index = Enum.with_index(trabajos)
    resultados = ejecutar_trabajos(trabajos_with_index, workers, [])

    resultados_ordenados =
      resultados
      # ordena con el index
      |> Enum.sort_by(fn {idx, _} -> idx end)
      # elimina el index y devuelve solo el resultado
      |> Enum.map(fn {_, resto} -> resto end)

    send(from, {:resultados, resultados_ordenados})
    send(parent, :batch_done)
  end

  def ejecutar_trabajos(jobs_with_index, _workers, _accumulated_results) do
    Enum.each(_workers, fn w -> send(w, {:work_todo, self()}) end)
    assign_and_wait(jobs_with_index, [], [])
  end

  # no quedan trabajos + no faltan resultados -> se devuelve
  defp assign_and_wait([], [], resultado_final) do
    resultado_final
  end

  defp assign_and_wait(trabajo_pend, resultado_pend, resultado_final) do
    receive do
      {:available, w} ->
        # si queda trabajo se envia a un trabajador libre
        case trabajo_pend do
          [{job, index} | job_tail] ->
            send(w, {:trabajo, self(), job})
            # llamamos de nuevo a la funcion sin la cabeza de los trabajos
            # asignamos el index del trabajo a resultados pendientes
            assign_and_wait(
              job_tail,
              [{index, w} | resultado_pend],
              resultado_final
            )

          # si no quedan trabajos pendientes descartamos el resto de mensajes
          # y llamamos de nuevo a la funcion a la espera de los resultados
          [] ->
            flush_available()
            assign_and_wait(trabajo_pend, resultado_pend, resultado_final)
        end

      # si se recibe un resultado se elimina el valor en resultado pendiente
      # y se añade al resultado final
      {:result, worker_pid, result} ->
        # Separamos el trabajo completado del resto
        {[{{idx, _}, _}], restantes} =
          resultado_pend
          |> Enum.with_index()
          |> Enum.split_with(fn {{_, pid}, _} -> pid == worker_pid end)

        new_resultados_pend = Enum.map(restantes, fn {{index, pend}, _} -> {index, pend} end)

        assign_and_wait(
          trabajo_pend,
          new_resultados_pend,
          [{idx, result} | resultado_final]
        )
    after
      # si no se recibe ninguna respuesta se vuelve a llamar la funcion
      500 ->
        assign_and_wait(trabajo_pend, resultado_pend, resultado_final)
    end
  end

  # descartar mensajes
  defp flush_available() do
    receive do
      {:available, _} -> flush_available()
    after
      0 -> :ok
    end
  end
end

defmodule Worker do
  def loop() do
    receive do
      {:trabajo, from, func} ->
        value = func.()
        result = proccess(value)
        send(from, {:result, self(), result})
        loop()

      {:work_todo, from} ->
        send(from, {:available, self()})
        loop()

      :stop ->
        :ok
    end
  end

  def proccess(x) do
    x * 2
  end
end
