FROM arm64v8/elixir:1.8-slim

RUN apt-get update && \
    apt-get install -y build-essential inotify-tools masscan

WORKDIR /vaporator
COPY . .

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

CMD ["mix run --no-halt"]
