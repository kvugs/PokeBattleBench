import asyncio
import contextlib
from typing import Final

from websockets.asyncio.client import ClientConnection, connect

SERVER_URL: Final[str] = "ws://127.0.0.1:8000/showdown/websocket"
AGENT_NAME_1: Final[str] = "Alpha123321"
AGENT_NAME_2: Final[str] = "Beta123321"


async def send_message(client: ClientConnection, message: str, player: str) -> None:
    """Send a message to the server and print it with the player's name."""
    print(f"({player})\t-->\t{message}")
    await client.send(message)


async def client_connect(url: str, player: str) -> None:
    async with connect(url) as client:
        # Naming the player is required to battle, chat, etc.
        # |/trn NAME,REGISTERED,ASSERTION
        # For local testing, only NAME is required
        await send_message(client, f"|/trn {player},0,", player)

        # Open websocket connection and listen for messages
        async for message in client:
            # The stream of messages flows at server frequency rate
            for line in message.splitlines():
                print(f"({player})\t<--\t{line}\n")


async def main() -> None:
    async with asyncio.TaskGroup() as clients:
        clients.create_task(client_connect(SERVER_URL, AGENT_NAME_1), name="alpha")
        clients.create_task(client_connect(SERVER_URL, AGENT_NAME_2), name="beta")


if __name__ == "__main__":
    with contextlib.suppress(KeyboardInterrupt):
        asyncio.run(main())
