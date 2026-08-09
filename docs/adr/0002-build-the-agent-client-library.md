# 0002 - Build the agent client library before adopting `poke-env`

- **Status:** Accepted
- **Date:** 2026-08-09
- **Deciders:** PokeBattleBench collaborators

## Context

`poke-env` already provides a Python interface for scripted agents, self-play, and reinforcement-learning workflows on Pokémon Showdown.
Adopting it would shorten the route to running a battle, but it would also remove much of the protocol and client implementation work the collaborators want to understand.
Building a complete competitor to `poke-env` would be unnecessarily broad and could delay the project without adding proportional learning value.
The project needs a boundary that supports a small custom implementation now without making a later dependency change unnecessarily expensive.

## Decision

Build the minimum project-owned Python client library required for two autonomous agents to complete one battle on a local Pokémon Showdown server.
Separate WebSocket transport, protocol parsing, battle state, legal-choice handling, and agent policy behind small interfaces.
Use `poke-env` as a source of inspiration and comparison, but do not make it an initial runtime dependency and do not aim for feature parity.
Reconsider adopting `poke-env` when custom integration work stops serving the learning objectives or materially prevents completion of the MVP.

## Consequences

The team gains direct experience with asynchronous Python, WebSockets, protocol handling, state synchronization, and agent boundaries.
The team also accepts responsibility for correctness, reconnection behavior, protocol changes, and maintenance of its integration code.
Keeping the scope narrow and the boundaries modular limits that responsibility and preserves a practical pivot path.
The first agent can remain a random legal policy because strategic strength is separate from proving the client library.
A pivot review must compare learning gained, remaining integration risk, maintenance burden, and progress toward a complete battle.

## Alternatives considered

| Option | Why not |
|---|---|
| Adopt `poke-env` immediately | It removes much of the networking and protocol work selected as an MVP learning objective. |
| Fork `poke-env` | A fork inherits a broad existing design and ongoing merge burden when only a narrow learning-oriented interface is needed. |
| Build a TypeScript agent client | The repository and intended later ML workflows are Python-based, while the server already supplies the required TypeScript and Node.js component. |
| Build full `poke-env` feature parity | It adds formats, training integrations, concurrency, and compatibility work outside the agreed MVP. |
