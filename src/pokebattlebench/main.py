import asyncio
from websockets.asyncio.client import connect

SERVER_URL = "ws://127.0.0.1:8000/showdown/websocket"
ALPHA = "Alpha123321"
BETA = "Beta123321"

async def main() -> None:
    async with (
        connect(SERVER_URL) as alpha,
        connect(SERVER_URL) as beta,
    ):
        await alpha.send(f"|/trn {ALPHA},0,")
        await beta.send(f"|/trn {BETA},0,")

        async for message in alpha:
            for line in message.splitlines():
                print(line + "\n")
           # message = await connection.recv()

if __name__ == "__main__":
    asyncio.run(main())
