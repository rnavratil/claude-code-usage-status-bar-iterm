#!/usr/bin/env python3

import asyncio
import subprocess
import iterm2

SCRIPT = "/Users/rnavratil/Desktop/claude-code-usage-status-bar-iterm.sh"


async def main(connection):
    component = iterm2.StatusBarComponent(
        short_description="Claude Usage",
        detailed_description="Claude API session and weekly usage limits",
        knobs=[],
        exemplar="session: 50% (Resets 8:30pm) | week: 10% (Resets Apr 25 at 3:00am) | extra: 66% (9.97/15.00 EUR)",
        update_cadence=10,
        identifier="com.rnavratil.claude-usage",
    )

    @iterm2.StatusBarRPC
    async def claude_usage(knobs):
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: subprocess.run(
                    ["bash", SCRIPT],
                    capture_output=True,
                    text=True,
                    timeout=10,
                ),
            )
            output = result.stdout.strip()
            return output if output else "[No data]"
        except Exception as e:
            return f"[Error: {e}]"

    await component.async_register(connection, claude_usage)


iterm2.run_forever(main)
