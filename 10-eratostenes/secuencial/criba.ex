defmodule Criba do

  def primos(n) do
      criba(rango(2,n))
  end

  def rango(x,m) when x>m, do: []

  def rango(x, m), do: [x | rango(x + 1, m)]

  def filter(_n, []), do: []
  def filter(n,[h|t]) do
    #no lo guardamos si es multiplo
     if (rem(h,n) == 0) do filter(n, t)

    else  [h| filter(n,t)]
  end
end

  def criba([]), do: []
  def criba([h | t]) do
    [h | criba(filter(h,t))]
  end
  end


IO.inspect Criba.primos(30)
