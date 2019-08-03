defmodule Filesync.Client.EventConsumerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Filesync.Client.EventConsumer

  @cloud %Filesync.Cloud.Dropbox{
    access_token: Application.get_env(:filesync, :dbx_token)
  }
  @cloud_root Application.get_env(:filesync, :cloud_root)

  setup_all do
    consumer_pid = Process.whereis(EventConsumer)
    Process.monitor(consumer_pid)
    :ok
  end

  test "event received from EventProducer processed to Cloud" do
    test_file = "/consumer_test.txt"
    File.write(test_file, "testing consumer")
    test_event = {:created, {"/", test_file}}

    Filesync.Client.EventProducer.enqueue(test_event)
    # Give event time to process
    :timer.sleep(1500)

    use_cassette "client/event_pipeline/consumer" do
      {:ok, %{results: [file | _]}} =
        Filesync.Cloud.list_folder(
          @cloud,
          @cloud_root
        )

      assert file.name == Path.basename(test_file)
    end

    Filesync.Client.EventProducer.enqueue({:deleted, {"/", test_file}})
    # Give event time to process
    :timer.sleep(1500)
  end
end
