defmodule Criba do

  def primos(n) do
      criba(rango(2,n))
  end

  def rango(x,m) when x>m, do: []

  def rango(x, m), do: [x | rango(x + 1, m)]

  def filter(_n, []), do: []

  def filter(n, [h | t]) when rem(h, n) == 0 do
    filter(n, t)
  end

  def filter(n, [h | t]) do
    [h | filter(n, t)]
  end

  def criba([]), do: []
  def criba([h | t]) do
    [h | criba(filter(h,t))]
  end
end
