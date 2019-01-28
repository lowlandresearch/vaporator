FROM arm32v7/elixir:1.8-slim

ENV MIX_ENV=prod

WORKDIR /app
COPY . .

RUN apt-get update && \
    apt-get install -y build-essential inotify-tools && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

CMD ["mix run"]