defmodule Vaporator.ClientFs.EventConsumerTest do
  use ExUnit.Case, async: false

  @cloudfs %Vaporator.Dropbox{
    access_token: System.get_env("VAPORATOR_CLOUDFS_ACCESS_TOKEN")
  }
  @cloudfs_root Application.get_env(:vaporator, :cloudfs_root)

  setup_all do 
    Vaporator.ClientFs.EventProducer.start_link()
    {:ok, consumer_pid} = Vaporator.ClientFs.EventConsumer.start_link()
    Process.monitor(consumer_pid)
    :ok
  end

  test "event received from EventProducer processed to CloudFs" do
    test_file = "/consumer_test.txt"
    File.write(test_file, "testing consumer")
    test_event = {:created, test_file}

    Vaporator.ClientFs.EventProducer.enqueue(test_event)

    :timer.sleep(5)

    {:ok, %{results: [file | _]}} = Vaporator.CloudFs.list_folder(
                                      @cloudfs,
                                      @cloudfs_root
                                    )

    assert file.name == Path.basename(test_file)
    Vaporator.ClientFs.EventProducer.enqueue({:deleted, test_file})
    :timer.sleep(5)
  end

end