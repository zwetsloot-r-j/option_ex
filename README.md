# OptionEx

OptionEx is a module for handling functions returning a `t:OptionEx.t/0`.
This module is inspired by the f# Option module, and [Railway Oriented Programming](https://fsharpforfunandprofit.com/rop/) as explained by Scott Wlaschin. This module is intended to make working with `nil` values more safe and convenient. For splitting tracks based on ok or error return values see [ResultEx](https://hexdocs.pm/result_ex/ResultEx.html#content).

The Option type consists of either a {:some, term} where the term represents a value, or the :none atom representing the lack of a value.

By replacing optional nil values with an `t:OptionEx.t/0`, it is no longer needed to match nil value cases. By using `OptionEx.map/2` or `OptionEx.bind/2` the function passed as second argument will only be executed when a value is present. By using `OptionEx.or_else/2` or `OptionEx.or_else_with/2` it is possible to add a default value, or behaviour to be executed only in case there is no value.

## Examples

```elixir
    iex> find_by_id = fn
    ...>   1 -> nil
    ...>   x -> %{id: x}
    ...> end
    ...>
    ...> find_by_id.(2)
    ...> |> OptionEx.return()
    {:some, %{id: 2}}
```

```elixir
    ...>
    ...> find_by_id.(1)
    ...> |> OptionEx.return()
    :none
```

```elixir
    ...>
    ...> find_by_id.(2)
    ...> |> OptionEx.return()
    ...> |> OptionEx.map(fn record -> record.id end)
    ...> |> OptionEx.map(&(&1 + 1))
    ...> |> OptionEx.bind(find_by_id)
    {:some, %{id: 3}}
```

```elixir
    ...>
    ...> find_by_id.(1)
    ...> |> OptionEx.return()
    ...> |> OptionEx.map(fn record -> record.id end)
    ...> |> OptionEx.map(&(&1 + 1))
    ...> |> OptionEx.bind(find_by_id)
    :none
```

```elixir
    ...>
    ...> find_by_id.(2)
    ...> |> OptionEx.return()
    ...> |> OptionEx.or_else_with(fn -> find_by_id.(0) end)
    %{id: 2}
```

```elixir
    ...>
    ...> find_by_id.(1)
    ...> |> OptionEx.return()
    ...> |> OptionEx.or_else_with(fn -> find_by_id.(0) end)
    %{id: 0}
```


## Installation

The package can be installed
by adding `option_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:option_ex, "~> 0.1.0"}
  ]
end
```

- Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
- Documentation is published on [HexDocs](https://hexdocs.pm).
- Documentation can be found at [https://hexdocs.pm/option_ex](https://hexdocs.pm/option_ex).
