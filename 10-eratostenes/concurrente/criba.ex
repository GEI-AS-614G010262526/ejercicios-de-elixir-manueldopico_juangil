defmodule Criba do
  def primo(n) do
  end

  def filtro(prime, next) do

    receive do
      {:number, num} ->
        if rem(num, prime) == 0 do
          filtro(prime, next)
        else
          if next == nil do
          new_next = spawn(fn -> filtro(num, nil) end)
          filtro(prime, new_next)
          else
            send(next, {:number, num})
            filtro(prime, next)
          end
        end
    end
  end
  
end
