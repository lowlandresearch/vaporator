defmodule Filesync.ClientFs.EventConsumerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Filesync.ClientFs.EventConsumer

  @cloudfs %Filesync.Dropbox{
    access_token: Application.get_env(:filesync, :dbx_token)
  }
  @cloudfs_root Application.get_env(:filesync, :cloudfs_root)

  setup_all do 
    consumer_pid = Process.whereis(EventConsumer)
    Process.monitor(consumer_pid)
    :ok
  end

  test "event received from EventProducer processed to CloudFs" do
    test_file = "/consumer_test.txt"
    File.write(test_file, "testing consumer")
    test_event = {:created, {"/", test_file}}

    Filesync.ClientFs.EventProducer.enqueue(test_event)
    :timer.sleep(1500) # Give event time to process

    use_cassette "clientfs/event_pipeline/consumer" do
      {:ok, %{results: [file | _]}} = Filesync.CloudFs.list_folder(
                                        @cloudfs,
                                        @cloudfs_root
                                      )

      assert file.name == Path.basename(test_file)
    end

    Filesync.ClientFs.EventProducer.enqueue({:deleted, {"/", test_file}})
    :timer.sleep(1500) # Give event time to process
  end

end
