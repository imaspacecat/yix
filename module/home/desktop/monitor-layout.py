import re
import subprocess
import sys
import time


def parse_outputs(query):
    outputs = {}
    current = None
    for line in query.splitlines():
        header = re.match(r"^(\S+) (connected|disconnected)\b", line)
        if header:
            current = {
                "connected": header[2] == "connected",
                "modes": [],
                "preferred": None,
            }
            outputs[header[1]] = current
        elif current is not None:
            mode = re.match(r"^\s+(\d+x\d+)\s+(.+)$", line)
            if mode:
                current["modes"].append(mode[1])
                if "+" in mode[2] and current["preferred"] is None:
                    current["preferred"] = mode[1]
    return outputs


def layout_arguments(outputs):
    connected = {
        name: output["preferred"] or output["modes"][0]
        for name, output in outputs.items()
        if output["connected"] and output["modes"]
    }
    if not connected:
        return []
    internal = next(
        (name for name in connected if re.match(r"^(eDP|LVDS|DSI)", name)),
        None,
    )
    external = sorted(name for name in connected if name != internal)
    sizes = {
        name: tuple(map(int, mode.split("x"))) for name, mode in connected.items()
    }
    external_width = sum(sizes[name][0] for name in external)
    external_height = max((sizes[name][1] for name in external), default=0)
    internal_width = sizes[internal][0] if internal else 0
    positions = {}
    x = max(0, (internal_width - external_width) // 2)
    for name in external:
        positions[name] = (x, external_height - sizes[name][1])
        x += sizes[name][0]
    if internal:
        positions[internal] = (max(0, (external_width - internal_width) // 2), external_height)
    arguments = []
    for name in outputs:
        arguments.extend(["--output", name])
        if name not in connected:
            arguments.append("--off")
            continue
        x, y = positions[name]
        arguments.extend([
            "--mode", connected[name], "--rotate", "normal", "--pos", f"{x}x{y}",
        ])
        if name == (internal or external[0]):
            arguments.append("--primary")
    return arguments


def watch(xrandr):
    previous = None
    while True:
        try:
            query = subprocess.check_output([xrandr, "--query"], text=True, timeout=10)
            outputs = parse_outputs(query)
            if outputs != previous:
                arguments = layout_arguments(outputs)
                if arguments:
                    subprocess.run([xrandr, *arguments], check=True, timeout=10)
                    previous = outputs
        except (subprocess.SubprocessError, OSError) as error:
            print(f"Monitor layout failed: {error}", file=sys.stderr, flush=True)
        time.sleep(2)


if __name__ == "__main__":
    watch(sys.argv[1])
