# docker-image-tanka-sops

A `linux/arm64` Docker image based on `debian:stable` that bundles a curated
toolchain for working with [Grafana Tanka](https://github.com/grafana/tanka)
and [Mozilla SOPS](https://github.com/getsops/sops) — including the supporting
utilities required to fetch Jsonnet dependencies and manipulate JSON/YAML.

The image is published to GitHub Container Registry as
`ghcr.io/callepuzzle/docker-image-tanka-sops:<tag>` on every GitHub release.
There is no `latest` tag and no multi-arch manifest.

## Included tools

| Tool         | Purpose                                                    | Source                                                              |
| ------------ | ---------------------------------------------------------- | ------------------------------------------------------------------- |
| `sops`       | Encrypted file editor (YAML/JSON/ENV/binary)               | `getsops/sops`                                                      |
| `tk`         | Tanka — `kubectl` for Jsonnet                             | `grafana/tanka`                                                     |
| `jb`         | Jsonnet dependency manager (`jsonnet-bundler`)             | `jsonnet-bundler/jsonnet-bundler`                                   |
| `jq`         | Command-line JSON processor                                | `stedolan/jq`                                                       |
| `yq`         | Command-line YAML/JSON processor (mikefarah)               | `mikefarah/yq`                                                      |
| `git`        | Version control (apt)                                      | Debian                                                              |
| `openssh-client` | SSH client (apt)                                       | Debian                                                              |

All binaries are downloaded from upstream GitHub releases and installed into
`/usr/local/bin/`. Versions are pinned in the `Dockerfile` URL paths — bump
them there to upgrade.

## Architecture

- **Platform:** `linux/arm64` only. The `Dockerfile` downloads arm64 binaries
  exclusively, and the build workflow pins `platforms: linux/arm64`. The
  `docker/setup-qemu-action` step in `.github/workflows/build.yml` is
  vestigial — there is no multi-arch build.
- **Base image:** `debian:stable`.
- **Runtime user:** a non-root user `tankasops` is created with
  `uid 999` and shell `/bin/bash`. No `WORKDIR`, `ENTRYPOINT`, or `CMD` is
  set — invoke the tools directly.
- **TLS:** `ca-certificates` is installed so the tools can verify HTTPS.

## Local build

```sh
docker build -t tanka-sops:dev .
```

Smoke-test the entrypoints (each must print a version, not
`command not found`):

```sh
docker run --rm tanka-sops:dev sops --version
docker run --rm tanka-sops:dev tk --version
docker run --rm tanka-sops:dev jb --version
docker run --rm tanka-sops:dev jq --version
docker run --rm tanka-sops:dev yq --version
docker run --rm tanka-sops:dev id
```

The last command should report `uid=999(tankasops) gid=999(tankasops)`.

To drop into a shell as the non-root user:

```sh
docker run --rm -it tanka-sops:dev bash
```

## Release flow

Releases are fully automated via GitHub Actions and
[semantic-release](https://github.com/semantic-release/semantic-release).

1. **Release (`release.yml`)** — runs on every push to `main`. It executes
   `npx semantic-release`, which determines the next version from the commit
   history (Conventional Commits: `feat:`, `fix:`, `chore:`, …) and creates
   a GitHub release. The config in `.releaserc.json` restricts this to the
   `main` branch and does **not** publish to npm.
2. **Build (`build.yml`)** — triggered by the `release: [released]` event.
   It logs in to GHCR, builds the image for `linux/arm64`, and pushes it
   under the tag emitted by semantic-release (e.g. `v1.2.3` →
   `ghcr.io/callepuzzle/docker-image-tanka-sops:1.2.3`).

### CI token

The release job authenticates with `secrets.PAT` — a **personal access
token**, not the default `GITHUB_TOKEN`. This is deliberate: the build
workflow is triggered by the `release: [released]` event, and pushes made
by the default token do not fan out to downstream workflows. If image
builds stop firing after a release, the first thing to check is that
`PAT` is still present and valid on the repository.

The PAT is managed at:
<https://github.com/settings/personal-access-tokens/4651935>

It needs at least the `contents: write` and `packages: write` scopes (the
latter is required to push to GHCR). Update the secret value in the
repository settings if the token is rotated, and update the link above if
the token is ever reissued under a different id.

## Repository layout

```
.
├── Dockerfile                         # the entire product
├── README.md
├── LICENSE
├── .releaserc.json                    # semantic-release config
├── .github/
│   └── workflows/
│       ├── build.yml                  # image build & publish (on release)
│       └── release.yml                # semantic-release (on push to main)
└── AGENTS.md                          # contributor notes for opencode
```

## Contributing

- Follow [Conventional Commits](https://www.conventionalcommits.org/) for
  commit messages — semantic-release depends on them to pick the next
  version. A `fix:` commit on `main` produces a patch release, a `feat:`
  produces a minor release, and a `BREAKING CHANGE:` footer produces a
  major release.
- To upgrade a tool, edit the version segment in its `wget` URL inside the
  `Dockerfile` and re-verify the URL still exists on the upstream release
  page.
- Do not introduce a `package.json`, build system, or test framework — the
  image is the product, and a smoke test is the only verification step.
