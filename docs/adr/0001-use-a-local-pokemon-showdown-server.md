# 0001 - Use a local Pokémon Showdown server for MVP battles

- **Status:** Accepted
- **Date:** 2026-08-09
- **Deciders:** PokeBattleBench collaborators

## Context

The MVP needs a real battle environment in which two autonomous agents can connect, exchange messages, make legal decisions, and finish a battle.
The collaborators want the first milestone to teach WebSockets and the relationship between a client and a server.
Reimplementing Pokémon battle mechanics would distract from that goal and would create a large correctness burden.
Calling the simulator directly inside the agent process would provide a smaller integration, but it would bypass the client-server lifecycle the team wants to learn.

## Decision

Run the official Pokémon Showdown server locally as the MVP battle environment.
The project-owned Python clients communicate with that server through its client-server protocol and treat it as the authority for battle progression and accepted choices.
The MVP remains local and does not automate play on a public server or ladder.

## Consequences

The project exercises real asynchronous connections, server messages, battle rooms, and connection lifecycle handling.
Pokémon Showdown owns battle mechanics, while PokeBattleBench owns the agent-facing client and policy boundaries.
The MVP depends on an external Node.js server and its protocol, so the project must define a repeatable startup and versioning approach.
Network and protocol failures become part of the system even when every component runs on one machine.
Direct in-process simulation remains available as a future option if throughput becomes more important than the networking learning objective.

## Alternatives considered

| Option | Why not |
|---|---|
| Call the Pokémon Showdown simulator directly | It bypasses the WebSocket and client-server behavior that forms part of the agreed learning objective. |
| Adopt `poke-env` for the first battle | It hides much of the protocol integration the team explicitly wants to learn. |
| Reimplement battle mechanics | It adds a very large correctness problem without improving the selected learning outcome. |
| Use a public Pokémon Showdown server | It introduces platform, consent, availability, and rate-limit concerns that are unnecessary for the MVP. |
