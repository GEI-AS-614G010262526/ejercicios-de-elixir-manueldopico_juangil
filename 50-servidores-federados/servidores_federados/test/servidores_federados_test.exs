defmodule ServidoresFederadosTest do
  use ExUnit.Case
  doctest ServidoresFederados

  setup do
    {:ok, _pid} = ServidoresFederados.start_link(:server1)

    GenServer.call(
      ServidoresFederados.via_tuple(:server1),
      {:register_actor, "user1", "Perfil de user1"}
    )

    GenServer.call(
      ServidoresFederados.via_tuple(:server1),
      {:register_actor, "user2", "Perfil de user2"}
    )

    {:ok, _pid} = ServidoresFederados.start_link(:server2)

    GenServer.call(
      ServidoresFederados.via_tuple(:server2),
      {:register_actor, "user5", "Perfil de user5"}
    )

    :ok
  end

  test "Consultar perfil" do
    assert ServidoresFederados.get_profile("user1@server1", "user2@server1") ==
             {:ok, "Perfil de user2"}
  end

  test "Enviar mensaje localmente" do
    assert ServidoresFederados.post_message("user1@server1", "user2@server1", "Holaa") ==
             {:ok, "Mensaje entregado localmente"}
  end

  test "Enviar mensaje a  otro servidor" do
    assert ServidoresFederados.post_message(
             "user1@server1",
             "user5@server2",
             "Hola a ti también"
           ) == {:ok, "Mensaje entregado localmente"}
    assert ServidoresFederados.retrieve_messages("user5@server2") == {:ok, ["Hola a ti también"]}
  end

  test "no dar un perfil a actores no registrados" do
    assert ServidoresFederados.get_profile("null@server1", "user1@server1") ==
             {:error, :actor_no_registrado}
  end
end
