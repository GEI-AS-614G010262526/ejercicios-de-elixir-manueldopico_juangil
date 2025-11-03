defmodule ServidoresFederados do
  use GenServer


  # API Cliente

  def start_link(server_name) do
  GenServer.start_link(__MODULE__, server_name, name: via_tuple(server_name))
  end

  def get_profile(requestor, actor) do
    GenServer.call(local_server(requestor), {:get_profile, requestor, actor})
  end

  #requestor es el actor que realiza la petición
  #actor     identifica el perfil que se desea consultar

  post_message(sender, receiver, message) do
    GenServer.call(local_server(sender), {:post_message, sender, receiver, message})
  end
  #sender   es el actor que envía el mensaje
  #receiver es el actor destinatario el mensaje
  #message  es el mensaje enviado

  retrieve_messages(actor) do
    GenServer.call(local_server(actor), {:retrieve_messages, actor})
  end
  #actor es el actor que realiza la petición


  # === Funciones auxiliares ===

  def via_tuple(server_name), do: {:global, {:servidor_federado, server_name}}

  # Extrae el nombre del servidor de un actor ("user@server")
  defp parse_actor(actor) do
    [user, server] = String.split(actor, "@")
    {user, String.to_atom(server)}
  end

  # Devuelve el pid del servidor donde está registrado el actor
  defp local_server(actor) do
    {_user, server} = parse_actor(actor)
    {:global, {:servidor_federado, server}}
  end


  @impl true
  def init(server_name) do
    state = %{
      name: server_name,
      actors: %{},   # %{ "user" => %{profile: ..., inbox: [...] } }
    }
    {:ok, state}
  end



    @impl true
  def handle_call({:get_profile, requestor, actor}, _from, state) do
    case validar_actor_local?(requestor, state) do
      false ->
        {:reply, {:error, :actor_no_registrado}, state}

      true ->
        {_user, server} = parse_actor(actor)
        if server == state.name do
          {:reply, get_profile_local(actor, state), state}
        else
          # Federado → contactar con el otro servidor
          {:reply, get_profile_federado(server, actor, state.name), state}
        end
    end
  end

  def handle_call({:post_message, sender, receiver, message}, _from, state) do
    case validar_actor_local?(sender, state) do
      false ->
        {:reply, {:error, :actor_no_registrado}, state}

      true ->
        {_user, receiver_server} = parse_actor(receiver)
        if receiver_server == state.name do
          {:reply, post_message_local(receiver, message, state), state}
        else
          {:reply, post_message_federado(receiver_server, receiver, message, state.name), state}
        end
    end
  end

  def handle_call({:retrieve_messages, actor}, _from, state) do
    case Map.get(state.actors, actor_usuario(actor)) do
      nil -> {:reply, {:error, :actor_no_registrado}, state}
      actor_data -> {:reply, {:ok, actor_data.inbox}, state}
    end
  end


end
