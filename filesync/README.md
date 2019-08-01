# Filesync

## Setting Up

### Configuration variables

- `:dbx_token` - the API key for Dropbox
- `:client_sync_dirs` - the local client directories to be synchronized by
  Filesync
- `:cloud_root` - the cloud filesystem path into which all files
  will be synchronized
- `:poll_interval` - number of seconds between polling client and cloud state.

### Separate environment config files

There are now three environment configuration files in the `config`
directory to be populated as needed for their corresponding
environments:

- `test.exs`
- `dev.exs`
- `prod.exs`

### `instance.exs` Configuration File

You must create the `config/instance.exs` file. This configuration is
for instance-specific settings. It will contain at least the following
application environment variables:

- `:dbx_token`
- `:client_sync_dirs`
- `:cloud_root`
- `:poll_interval`

## Architecture
<img src="./assets/architecture.svg">

## Filesync.Client

Receives and processes events from the client filesystem to a cloud filesystem

### Client.EventMonitor
**Type:**
[GenServer](hexdocs.pm/elixir/GenServer.html)

`Client.EventMonitor` polls the current state of `client` and `cloud` and updates `cloud` where states differ.

Directories that will be monitored can be provided as a list of
binaries of **absolute paths** in the application variable
`:sync_dirs`. This will be set explicitly in either one of the
environment config files (`{test,dev,prod}.exs`) or in the
instance-specific environment config, `instance.exs`.

### Filesync.Cache
**Type:**
[GenServer](hexdocs.pm/elixir/GenServer.html), 
[ETS](https://hexdocs.pm/ets/Ets.html)

`Filesync.Cache` provides an interface to the ets file hash cache.

### Client.EventProducer
**Type:**
[GenStage.BroadcastDispatcher
](https://hexdocs.pm/gen_stage/GenStage.Dispatcher.html) (Producer)

#### Event Queue
Receives file events from `Client.EventMonitor` and stores them using an 
[erlang queue](http://erlang.org/doc/man/queue.html).

#### Event Demand
When `Client.EventConsumer` requests events for processing, 
`Client.EventProducer` dequeues the number of requested 
events and responds with the events.

### Client.EventConsumer
**Type:**
[GenStage ConsumerSupervisor
](https://hexdocs.pm/gen_stage/ConsumerSupervisor.html)

`Client.EventConsumer` receives events from `Client.EventProducer` and 
spawns one `Client.EventProcessor` per event for concurrent processing.

### Client.EventProcessor
**Type:**
[Task](https://hexdocs.pm/elixir/Task.html)

`Client.EventProcessor` is spawned by `Client.EventConsumer` to process 
a single event using `Filesync.Client.process_event/1` to call the necessary 
`Filesync.Cloud` sync function.
