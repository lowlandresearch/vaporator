# Vaporator

Before starting the application, you must set three environment variables.

* `VAPORATOR_CLOUDFS_ACCESS_TOKEN` - API Key for Cloud FileSystem
* `VAPORATOR_CLOUDFS_PATH` - Target directory path to sync local files
* `VAPORATOR_SYNC_DIRS` - comma seperated list of local Client FileSystem
absolute paths to sync to Cloud FileSystem

## Architecture
![alt text](
  https://github.com/lowlandresearch/vaporator/lib/vaporator/architecture.png
  "Vaporator Architecture"
)

## Vaporator.ClientFs

Receives and processes events from the client filesystem to a cloud filesystem

### ClientFs.EventMonitor
**Type:**
[GenServer](hexdocs.pm/elixir/GenServer.html)

`ClientFs.EventMonitor` subscribes to the client
[file_system](https://hexdocs.pm/file_system) and casts the received file 
events to `ClientFs.EventProducer`.

Directories that will be monitored can be provided with the environment 
variable `VAPORATOR_SYNC_DIRS="/abspath1,/abspath2"`. *The directory 
paths must be absolute paths.*

### ClientFs.EventProducer
**Type:**
[GenStage.BroadcastDispatcher
](https://hexdocs.pm/gen_stage/GenStage.Dispatcher.html) (Producer)

#### Event Queue
Receives file events from `ClientFs.EventMonitor` and stores them using an 
[erlang queue](http://erlang.org/doc/man/queue.html).

#### Event Demand
When `ClientFs.EventConsumer` requests events for processing, 
`ClientFs.EventProducer` dequeues the number of requested 
events and responds with the events.

### ClientFs.EventConsumer
**Type:**
[GenStage ConsumerSupervisor
](https://hexdocs.pm/gen_stage/ConsumerSupervisor.html)

`ClientFs.EventConsumer` receives events from `ClientFs.EventProducer` and 
spawns one `ClientFs.EventProcessor` per event for concurrent processing.

### ClientFs.EventProcessor
**Type:**
[Task](https://hexdocs.pm/elixir/Task.html)

`ClientFs.EventProcessor` is spawned by `ClientFs.EventConsumer` to process 
a single event using `Vaporator.ClientFs.process_event/1` to call the necessary 
`Vaporator.CloudFs` sync function.