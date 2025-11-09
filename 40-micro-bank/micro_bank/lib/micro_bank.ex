defmodule MicroBank do
  use GenServer

  # API Cliente

  def start_link(cuentas) do
    GenServer.start_link(__MODULE__, cuentas)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def deposit(pid, who, amount) do
    GenServer.call(pid, {:deposit, who, amount})
  end

  def withdraw(pid, who, amount) do
    GenServer.call(pid, {:withdraw, who, amount})
  end

  def ask(pid, who) do
    GenServer.call(pid, {:ask, who})
  end

  # Callbacks
  @impl true
  def init(cuentas) do
    {:ok, cuentas}
  end

  @impl true
  def handle_call({:deposit, who, amount}, _from, cuentas) do
    new_balance = Map.get(cuentas, who, 0) + amount
    new_state = Map.put(cuentas, who, new_balance)
    {:reply, {:ok, new_balance}, new_state}
  end

  @impl true
  def handle_call({:ask, who}, _from, cuentas) do
    balance = Map.get(cuentas, who, 0)
    {:reply, {:ok, balance}, cuentas}
  end

  @impl true
  def handle_call({:withdraw, who, amount}, _from, cuentas) do
    balance = Map.get(cuentas, who, 0)

    if balance < amount do
      {:reply, {:error}, cuentas}
    else
      new_balance = balance - amount
      {:reply, {:ok, new_balance}, cuentas}
    end
  end
end



defmodule MicroBankSupervisor do
  use Supervisor

  def start_link(initial_accounts \\ %{}) do
    Supervisor.start_link(__MODULE__, initial_accounts, name: __MODULE__)
  end

  @impl true
  def init(initial_accounts) do
    children = [
      {MicroBank, initial_accounts}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

end
