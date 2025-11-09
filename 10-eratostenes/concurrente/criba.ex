defmodule Criba do
  def primo(n) do
    criba(n)
  end

  def rango(x, m) when x > m, do: []

  def rango(x, m), do: [x | rango(x + 1, m)]

  def criba(n) do
    task = Task.async(fn -> colector() end)
    send(task.pid, {:prime, 2})

    first = spawn(fn -> filtro(2, nil, task.pid) end)

    Enum.each(rango(3, n), fn x ->
      send(first, {:number, x})
    end)

    send(first, {:done, task.pid})

    Task.await(task)
  end

  def filtro(prime, next, colector) do
    receive do
      {:number, num} ->
        cond do
          rem(num, prime) == 0 ->
            filtro(prime, next, colector)

          next == nil ->
            send(colector, {:prime, num})
            new_next = spawn(fn -> filtro(num, nil, colector) end)
            filtro(prime, new_next, colector)

          true ->
            send(next, {:number, num})
            filtro(prime, next, colector)
        end

      {:done, colector} ->
        if next != nil do
          send(next, {:done, colector})
        else
          send(colector, :done)
        end
    end
  end

  def colector(primes \\ []) do
    receive do
      {:prime, p} ->
        colector([p | primes])

      :done ->
        Enum.reverse(primes)
    end
  end
end
