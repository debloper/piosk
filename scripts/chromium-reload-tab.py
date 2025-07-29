#!/usr/bin/env python3
# This is done in Python because doing websocket comms in bash is a pain in the ...
# Needs: "sudo apt install python3-websockets" to work
import asyncio
import websockets
import json
import subprocess

# Get the WebSocket URL for the first tab
debug_info = subprocess.check_output(["curl", "-s", "http://localhost:9222/json"])
tabs = json.loads(debug_info)
ws_url = tabs[0]["webSocketDebuggerUrl"]

# Send reload command
async def reload_tab():
    async with websockets.connect(ws_url) as ws:
        await ws.send(json.dumps({
            "id": 1,
            "method": "Page.reload",
            "params": {"ignoreCache": False}
        }))
        response = await ws.recv()
        print("Reloaded tab:", response)

asyncio.run(reload_tab())
