defmodule Vaporator.ClientFs.EventConsumerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @cloudfs %Vaporator.Dropbox{
    access_token: Application.get_env(:vaporator, :dbx_token)
  }
  @cloudfs_root Application.get_env(:vaporator, :cloudfs_root)

  setup_all do 
    Vaporator.ClientFs.EventProducer.start_link()

    # If the Application callback line in mix.exs is commented out,
    # this works. If it is uncommented (i.e. if the Application is
    # allowed to start prior to testing), then this fails with:
    #
    # ** (MatchError) no match of right hand side value: {:error, {:already_started, #PID<0.331.0>}}
    {:ok, consumer_pid} = Vaporator.ClientFs.EventConsumer.start_link()
    Process.monitor(consumer_pid)
    :ok
  end

  test "event received from EventProducer processed to CloudFs" do
    test_file = "/consumer_test.txt"
    File.write(test_file, "testing consumer")
    test_event = {:created, {"/", test_file}}

    Vaporator.ClientFs.EventProducer.enqueue(test_event)
    :timer.sleep(1500) # Give event time to process

    use_cassette "clientfs/event_pipeline/consumer" do
      {:ok, %{results: [file | _]}} = Vaporator.CloudFs.list_folder(
                                        @cloudfs,
                                        @cloudfs_root
                                      )

      assert file.name == Path.basename(test_file)
    end

    Vaporator.ClientFs.EventProducer.enqueue({:deleted, {"/", test_file}})
    :timer.sleep(1500) # Give event time to process
  end

end
