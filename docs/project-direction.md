# Project direction

## Status

This document records the direction agreed by the PokeBattleBench collaborators on 2026-08-09.
It replaces earlier personal proposals as the current source of truth for the MVP.

## Shared learning objective

PokeBattleBench is a learning project for building dependable software around autonomous game agents.
Individual interests may differ, but the collaborators share an interest in learning how to build a clean, modular, and maintainable foundation that can later support agent evaluation, data engineering, and machine learning.

The MVP emphasizes end-to-end ownership of a small working system.
It should teach the team how clients and servers communicate, how WebSocket-based programs manage asynchronous state, and how autonomous agents interact with an external battle environment.

The team values simplicity, clear module boundaries, automated tests, explicit decisions, and code that remains understandable when requirements change.
The team will avoid complexity that does not solve an observed MVP problem.

## MVP outcome

The MVP is a small project-owned alternative to the narrowest part of [`poke-env`](https://github.com/hsahovic/poke-env).
It must connect to a locally operated [`pokemon-showdown`](https://github.com/smogon/pokemon-showdown) server and complete one battle between two autonomous agents.

A successful MVP demonstrates this complete flow:

1. Start or connect to a local Pokémon Showdown server.
2. Connect two project-owned agent clients through the server protocol.
3. Initiate a battle between the agents.
4. Keep each agent's local battle state synchronized with server messages.
5. Determine the choices the server permits at each decision point.
6. Let each agent select and submit a legal action.
7. Continue until the server declares a winner or reports a controlled failure.
8. Expose enough output to understand the result and diagnose a failure.

The first policies may choose randomly among legal actions.
Playing well is not required for the MVP.
Completing a valid battle through the real client-server boundary is the learning milestone.

## Accepted technical direction

- The official Pokémon Showdown server provides the battle environment, protocol, and battle rules.
- The first agent integration is a project-owned Python library in this repository.
- The library may study `poke-env` for proven concepts and implementation lessons without making `poke-env` a runtime dependency.
- The team will keep the first implementation intentionally small and will not attempt feature parity with `poke-env`.
- The library must separate transport, protocol parsing, battle state, legal-choice handling, and agent policy so that any one part can change without rewriting the others.
- The team may pivot to adopting `poke-env` if maintaining the custom integration stops producing sufficient learning value or prevents progress toward the MVP.

The reasons and consequences are recorded in [ADR 0001](adr/0001-use-a-local-pokemon-showdown-server.md) and [ADR 0002](adr/0002-build-the-agent-client-library.md).

## Deferred work

The following areas are valuable, but they come after the basic autonomous battle works:

- large evaluation suites and statistical agent comparisons;
- parallel or distributed battle execution;
- training-data pipelines;
- experiment tracking and other MLOps systems;
- heuristic, supervised, reinforcement-learning, or language-model agents;
- production deployment and operational scaling;
- a dedicated PokeBattleBench user interface;
- public-server or public-ladder automation.

Deferring these areas is a sequencing decision, not a rejection of the longer-term laboratory vision.

## Open questions

The meeting did not settle the following details:

- ~~the first Pokémon generation, battle format, teams, or information rules~~ - answered on 2026-08-30, see the [decision log](decisions.md): Gen 3 singles, `gen3randombattle`, server-generated random teams, and each agent reads only its own connection;
- the Python WebSocket library and detailed package layout;
- the local server startup and version-pinning approach;
- the exact normalized battle-state and agent interfaces;
- the minimum logs or structured result required from one battle;
- whether a later visual interface should reuse the separate [`pokemon-showdown-client`](https://github.com/smogon/pokemon-showdown-client) or be built specifically for PokeBattleBench.

The Pokémon Showdown client is not required for two autonomous agents to complete the MVP.
It can connect to an arbitrary local Showdown server and may be useful for observing battles, but it is a separate AGPL-3.0 project.
The team must investigate its fit, integration cost, and licensing consequences before deciding to reuse or modify it.

## Working agreement follow-up

The collaborators plan to create a shared document describing their preferred coding practices.
Until that agreement exists, contributors follow the repository's current contribution, test, type, formatting, and decision-recording rules.
