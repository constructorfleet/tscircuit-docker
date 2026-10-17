# Self-hosted tscircuit containers

This repository builds two images from upstream projects:

- **Web app:** the full browser application from [tscircuit.com](https://github.com/tscircuit/tscircuit.com).
- **CLI dev server:** `tsci dev` from the [tscircuit CLI](https://github.com/tscircuit/cli), with a browser code editor and live board previews.

## Choose an image

### Full tscircuit.com web app

```yaml
services:
  tscircuit-web:
    image: ghcr.io/constructorfleet/tscircuit-web:latest
    ports:
      - "5173:5173"
    restart: unless-stopped
```

The full app runs on `http://localhost:5173`. It is still the upstream development server with its fake API; see [full-site limitations](#full-site-limitations).

### CLI browser editor and development server

The CLI image starts `tsci dev` on port 3020. When its workspace is empty, it creates a starter project there. The Compose service mounts `./projects` from the host, so source files and generated snapshots persist across container restarts.

```sh
docker compose --profile cli up -d tscircuit-cli
```

Open `http://localhost:3020`. Edit the project in the browser; PCB, schematic, and 3D previews update as the circuit changes. The service handles one shared project directory, so concurrent users share and can change those same files.

### Simulate and export previews with the CLI

Run CLI commands in the running container. The examples use the starter file created in `./projects`:

```sh
docker compose exec tscircuit-cli tsci simulate analog index.circuit.tsx
docker compose exec tscircuit-cli tsci snapshot --3d index.circuit.tsx
```

`tsci simulate analog` prints analog SPICE simulation results in the terminal. The circuit must define a simulation and probes. The command fetches tscircuit's JavaScript simulation engine from `jscdn.tscircuit.com` on first use, so the container needs outbound network access. `tsci snapshot --3d` writes PCB, schematic, and 3D preview images under the mounted project workspace; use `--pcb-only`, `--schematic-only`, or `--simulation-only` to narrow the output.

The separate `tsci simulate return-current` command is an electromagnetic simulation using Palace. The CLI image does not include Palace, Gmsh, or VTK; run that mode only after installing/providing those tools and selecting the Python environment with `--python` or `PALACE_PYTHON`.

## Compose example for both images

The included `compose.yaml` defines the full website and the CLI service. The CLI service is behind the `cli` profile, so start only the mode you want:

```sh
docker compose up -d tscircuit-web
docker compose --profile cli up -d tscircuit-cli
```

Place either interface behind HTTPS and authentication before exposing it beyond a trusted network. The CLI browser server can read and modify files in its mounted workspace.

## Full-site limitations

- The full website image is distinct from the CLI image; it does not install the CLI.
- The app uses the upstream fake snippets API and fake Stripe handler. The fake API has in-memory/demo behavior; do not treat its designs or accounts as durable production data.
- The hosted site's real authentication, registry, collaboration, billing, AI, package storage, and ordering workflows depend on upstream services and Vercel API functions. This container does not recreate those production backends, guarantee those integrations, or make the hosted checkout/order flow self-hosted.
- The upstream development server is not a hardened production web server. Restrict access and place it behind TLS and authentication. Use only on trusted networks until you have replaced the fake API and reviewed the upstream app's security and persistence model.
- This image follows upstream `main` by default at build time. Pin an upstream branch or tag with `--build-arg TSCIRCUIT_REF=<ref>` to reproduce a chosen upstream revision.
- Because the build pulls upstream source, rebuilds can change when upstream `main` changes. For reproducible releases, pin `TSCIRCUIT_REF` to an immutable commit and update it deliberately.

## CLI image notes

- `tsci dev` serves the browser UI from the mounted local workspace; it is a development server, not a multi-user hosted project service.
- The image installs the latest published `tscircuit` CLI by default. Pin a CLI npm version locally with `--build-arg TSCIRCUIT_CLI_VERSION=<version>` when building `Dockerfile.cli`.
- Most board previews and analog SPICE simulation run through the CLI/browser toolchain. More specialized commands can need external services or local tools; see the simulate notes above.

## Build and smoke-check locally

```sh
docker build -t tscircuit-web .
docker run --rm -d --name tscircuit-web -p 5173:5173 tscircuit-web
./smoke-test.sh
docker stop tscircuit-web

docker build -f Dockerfile.cli -t tscircuit-cli .
docker run --rm -d --name tscircuit-cli -p 3020:3020 -v "$PWD/projects:/workspace" tscircuit-cli
./smoke-test-cli.sh
docker stop tscircuit-cli
```

The smoke checks verify the web editor/fake API and the CLI browser preview page.

## Published image and workflow

The GitHub Actions workflow publishes:

- `ghcr.io/constructorfleet/tscircuit-web` and `ghcr.io/constructorfleet/tscircuit-cli`, each with `latest` from pushes to `main`
- Each image also gets a branch tag for branch pushes
- Each image gets `<version>`, major, and major.minor tags from `v*.*.*` tags (for example `v1.2.3` publishes `1.2.3`, `1.2`, and `1`)

The workflow uses the repository-provided `GITHUB_TOKEN`; no personal access token or repository secret is required. Its permissions are limited to reading source and writing packages. Organization policy must allow GitHub Actions to create packages. If package creation is restricted, grant the repository Actions access to the GHCR package. Set the package visibility to public in the package settings if anonymous pulls are desired; GHCR packages may otherwise be private by default. Private pulls require GitHub authentication with package read access.

## License and upstream attribution

The upstream tscircuit.com project is MIT licensed. This repository contains the container recipe and workflow; the application source is fetched from upstream during image builds. See the [upstream license](https://github.com/tscircuit/tscircuit.com/blob/main/LICENSE).
