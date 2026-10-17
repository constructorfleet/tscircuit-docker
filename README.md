# Self-hosted tscircuit web editor

This repository builds a container for the browser-based editor from the upstream [tscircuit.com](https://github.com/tscircuit/tscircuit.com) project. It runs upstream's local development server because that is the upstream-supported mode that includes its fake API.

## Run with Docker Compose

```yaml
services:
  tscircuit:
    image: ghcr.io/constructorfleet/tscircuit-web:latest
    ports:
      - "5173:5173"
    restart: unless-stopped
```

Save this as `compose.yaml`, then run `docker compose up -d`. Open `http://localhost:5173`. Put it behind your existing HTTPS reverse proxy and authentication layer before exposing it outside a trusted network.

To use a published release, replace `latest` with a version tag such as `1.2.3`. For local builds, run `docker build -t tscircuit-web .` and change the Compose image to `tscircuit-web`.

## What works and what does not

- This is the full tscircuit.com browser application, not the `tsci` CLI.
- The app uses the upstream fake snippets API and fake Stripe handler. The fake API has in-memory/demo behavior; do not treat its designs or accounts as durable production data.
- The hosted site's real authentication, registry, collaboration, billing, AI, package storage, and ordering workflows depend on upstream services and Vercel API functions. This container does not recreate those production backends, guarantee those integrations, or make the hosted checkout/order flow self-hosted.
- The upstream development server is not a hardened production web server. Restrict access and place it behind TLS and authentication. Use only on trusted networks until you have replaced the fake API and reviewed the upstream app's security and persistence model.
- This image follows upstream `main` by default at build time. Pin an upstream branch or tag with `--build-arg TSCIRCUIT_REF=<ref>` to reproduce a chosen upstream revision.
- Because the build pulls upstream source, rebuilds can change when upstream `main` changes. For reproducible releases, pin `TSCIRCUIT_REF` to an immutable commit and update it deliberately.

## Build and smoke-check locally

```sh
docker build -t tscircuit-web .
docker run --rm -d --name tscircuit-web -p 5173:5173 tscircuit-web
./smoke-test.sh
docker stop tscircuit-web
```

The smoke check verifies the editor page and the upstream fake render-demo route.

## Published image and workflow

The GitHub Actions workflow publishes:

- `ghcr.io/constructorfleet/tscircuit-web:latest` from pushes to `main`
- `ghcr.io/constructorfleet/tscircuit-web:<branch>` for branch pushes
- `ghcr.io/constructorfleet/tscircuit-web:<version>`, plus major and major.minor tags, for `v*.*.*` tags (for example `v1.2.3` publishes `1.2.3`, `1.2`, and `1`)

The workflow uses the repository-provided `GITHUB_TOKEN`; no personal access token or repository secret is required. Its permissions are limited to reading source and writing packages. Organization policy must allow GitHub Actions to create packages. If package creation is restricted, grant the repository Actions access to the GHCR package. Set the package visibility to public in the package settings if anonymous pulls are desired; GHCR packages may otherwise be private by default. Private pulls require GitHub authentication with package read access.

## License and upstream attribution

The upstream tscircuit.com project is MIT licensed. This repository contains the container recipe and workflow; the application source is fetched from upstream during image builds. See the [upstream license](https://github.com/tscircuit/tscircuit.com/blob/main/LICENSE).
