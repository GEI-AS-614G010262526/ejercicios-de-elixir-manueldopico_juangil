defmodule ServidoresFederados do
  use GenServer

  # API CLIENTE

  def start_link(server_name) do
  GenServer.start_link(__MODULE__, server_name, name: via_tuple(server_name))
  end

  def get_profile(requestor, actor) do
    GenServer.call(local_server(requestor), {:get_profile, requestor, actor})
  end

  #requestor es el actor que realiza la petición
  #actor     identifica el perfil que se desea consultar

  def post_message(sender, receiver, message) do
    GenServer.call(local_server(sender), {:post_message, sender, receiver, message})
  end
  #sender   es el actor que envía el mensaje
  #receiver es el actor destinatario el mensaje
  #message  es el mensaje enviado

  def retrieve_messages(actor) do
    GenServer.call(local_server(actor), {:retrieve_messages, actor})
  end
  #actor es el actor que realiza la petición


  #FUNCIONES AUXILIARES

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

  # Extrae solo el "user" de "user@server"
  defp actor_usuario(actor) do
    {user, _server} = parse_actor(actor)
    user
  end

  # Comprueba si un actor está registrado en el servidor actual
  defp validar_actor_local?(actor, state) do
    user = actor_usuario(actor)
    Map.has_key?(state.actors, user)
  end

  #CALLBACKS

  @impl true
  def init(server_name) do
    state = %{
      name: server_name,
      actors: %{},   # %{ "user" => %{profile: ..., inbox: [...] } }
    }
    {:ok, state}
  end

  #una función para registrar actores (creo que es necesario para meterlos y probar)
  def handle_call({:register_actor, username, profile}, _from, state) do
    new_actors = Map.put(state.actors, username, %{profile: profile, inbox: []})
    {:reply, {:ok, "Actor registrado"}, %{state | actors: new_actors}}
  end

  def handle_call({:get_profile, requestor, actor}, _from, state) do
    case validar_actor_local?(requestor, state) do
      false ->
        {:reply, {:error, :actor_no_registrado}, state}

      true ->
        {_user, server} = parse_actor(actor)
        if server == state.name do
          {:reply, get_profile_local(actor, state), state}
        else
          # Si es federado contacta con el otro servidor
          {:reply, get_profile_federado(server, actor, state.name), state}
        end
    end
  end


  # Cuando otro servidor pide el perfil de uno de nuestros actores
  def handle_call({:federated_get_profile, _from_server, actor}, _from, state) do
    {:reply, get_profile_local(actor, state), state}
  end

  def handle_call({:post_message, sender, receiver, message}, _from, state) do
    case validar_actor_local?(sender, state) do
      false ->
        {:reply, {:error, :actor_no_registrado}, state}

      true ->
        {_user, receiver_server} = parse_actor(receiver)
        if receiver_server == state.name do
    case post_message_local(receiver, message, state) do
          {:ok, msg, new_state} -> {:reply, {:ok, msg}, new_state}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end
        else
          {:reply, post_message_federado(receiver_server, receiver, message, state.name), state}
        end
    end
  end

    # Cuando otro servidor nos envía un mensaje federado
def handle_call({:federated_post_message, _from_server, receiver, message}, _from, state) do
  case post_message_local(receiver, message, state) do
    {:ok, msg, new_state} -> {:reply, {:ok, msg}, new_state}
    {:error, reason, state} -> {:reply, {:error, reason}, state}
  end
end

  def handle_call({:retrieve_messages, actor}, _from, state) do
    case Map.get(state.actors, actor_usuario(actor)) do
      nil ->
        {:reply, {:error, :actor_no_registrado}, state}
      actor_data ->
        {:reply, {:ok, actor_data.inbox}, state}
    end
  end

  #FUNCIONES PRIVADAS

  # Caso local: devolver perfil si existe
  defp get_profile_local(actor, state) do
    user = actor_usuario(actor)
    case Map.get(state.actors, user) do
      nil -> {:error, :actor_no_encontrado}
      %{profile: profile} -> {:ok, profile}
    end
  end

  # Caso federado: pedir perfil al otro servidor
  defp get_profile_federado(server, actor, from_server) do
    GenServer.call(via_tuple(server), {:federated_get_profile, from_server, actor})
  end


  # Enviar mensaje localmente
  defp post_message_local(receiver, message, state) do
    user = actor_usuario(receiver)
    case Map.get(state.actors, user) do
      nil -> {:error, :destinatario_no_encontrado, state}
      actor_data ->
        updated_inbox = [message | actor_data.inbox]
        new_state = put_in(state.actors[user].inbox, updated_inbox)
        {:ok, "Mensaje entregado localmente", new_state}
    end
  end

  # Caso federado: reenviar mensaje al servidor de destino
  defp post_message_federado(receiver_server, receiver, message, from_server) do
    GenServer.call(via_tuple(receiver_server),
      {:federated_post_message, from_server, receiver, message})
  end


end
