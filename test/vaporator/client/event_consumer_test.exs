defmodule Vaporator.Client.EventConsumerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @cloud %Vaporator.Cloud.Dropbox{
    access_token: Application.get_env(:vaporator, :dbx_token)
  }
  @cloud_root Application.get_env(:vaporator, :cloud_root)

  test "event received from EventProducer processed to Cloud" do
    test_file = "/consumer_test.txt"
    File.write(test_file, "testing consumer")
    test_event = {:created, {"/", test_file}}

    Vaporator.Client.EventProducer.enqueue(test_event)
    # Give event time to process
    :timer.sleep(1500)

    use_cassette "client/event_pipeline/consumer" do
      {:ok, %{results: [file | _]}} =
        Vaporator.Cloud.list_folder(
          @cloud,
          @cloud_root
        )

      assert file.name == Path.basename(test_file)
    end

    Vaporator.Client.EventProducer.enqueue({:deleted, {"/", test_file}})
    # Give event time to process
    :timer.sleep(1500)
  end
end
