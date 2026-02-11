# PanllBeam

BEAM runtime service for PanLL with selectable API frontdoors:

- HTTP (Bandit + Plug)
- GraphQL (Absinthe + Bandit)
- gRPC (grpc-elixir + protobuf)

All three can run together or be enabled selectively.

## API Modes

Control enabled protocols with `PANLL_BEAM_APIS`:

```bash
# Enable all protocols (default)
export PANLL_BEAM_APIS="http,graphql,grpc"

# HTTP + gRPC only
export PANLL_BEAM_APIS="http,grpc"

# GraphQL only
export PANLL_BEAM_APIS="graphql"
```

## Ports

```bash
# HTTP (default: 4100)
export PANLL_BEAM_HTTP_PORT=4100

# GraphQL (default: 4101)
export PANLL_BEAM_GRAPHQL_PORT=4101

# gRPC (default: 50051)
export PANLL_BEAM_GRPC_PORT=50051

# Backward compatible legacy HTTP port override
export PANLL_BEAM_PORT=4100
```

## Endpoints

### HTTP

- `GET /healthz`
- `GET /v1/status`

### GraphQL

- `POST /graphql`
- `GET /graphiql`
- `GET /healthz`

GraphQL query example:

```graphql
query {
  health
  status {
    service
    status
    runtime
    version
    apis
  }
}
```

### gRPC

Service: `panll.v1.StatusService`

- `GetStatus(StatusRequest) returns (StatusReply)`

## Run

```bash
mix deps.get
mix test
mix run --no-halt
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `panll_beam` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:panll_beam, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/panll_beam>.
