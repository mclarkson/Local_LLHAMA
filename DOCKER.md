# Running with Docker/Podman

Tested on Linux, Fedora, as a normal user using Podman.

Must be logged into Gnome as a normal user, then lock the screen.

## Run

Write a `.env` file in the current directory.

Run with:

```bash
podman run --net=host \
  --userns=keep-id -v .env:/home/llhama-usr/Local_LLHAMA/.env:z \
  -v /run/user/1000/pulse:/run/user/1000/pulse:z \
  -v ~/.config/pulse/cookie:/home/llhama-usr/.config/pulse/cookie:z \
  -e LLHAMA_DEV_MODE=1 \
  -e PULSE_SERVER=unix:/run/user/1000/pulse/native \
  -e PULSE_COOKIE=/home/llhama-usr/.config/pulse/cookie \
  -e XDG_RUNTIME_DIR=/run/user/1000 \
  --name local_llhama -d local_llhama:latest python -m local_llhama.run_system
```

Replace `1000` with your user ID.

Tail logs with:

```bash
podman logs -f local_llhama
```

## Why/What

| Option           | Description                                             |
|------------------|---------------------------------------------------------|
| --net=host       | Keeps networking simple and uses the host network.      |
| --userns=keep-id | Keeps the calling userid so container can access audio. |
| -v               | Mount host_file_dir:into_container_file_dir.            |
| -e               | Sets environment variables inside the container.        |
| -d               | Run as daemon in the background.                        |

