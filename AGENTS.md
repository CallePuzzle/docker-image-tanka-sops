# AGENTS.md

Single-Dockerfile repo that builds a `debian:stable` image bundling prebuilt
binaries: `sops`, `jq`, `yq`, `jb` (jsonnet-bundler), `tk` (Tanka), plus
`git` and `openssh-client`. A non-root user `tankasops` (uid 999) is created.

There is no application code, no tests, no lint, no typecheck, no
`package.json`, and no source tree. The Dockerfile is the entire product.

## Architecture quirks

- **arm64-only.** All binary download URLs in `Dockerfile:5-9` are
  `linux-arm64`. `.github/workflows/build.yml:29` only requests
  `platforms: linux/arm64`. The QEMU setup step in `build.yml:20-21` is
  vestigial — there is no multi-arch build. Don't add amd64 URLs without also
  changing the workflow.
- **Binary versions are pinned in the Dockerfile URL paths.** To upgrade any
  tool, edit the version segment in its `wget` URL (and re-verify the URL
  still exists on the upstream release page).
- **Tools land in `/usr/local/bin/`** and are made executable in a single
  `chmod +x` at `Dockerfile:10`.

## Local development

Build the image locally:

```sh
docker build -t tanka-sops:dev .
```

Smoke-test the entrypoints (all must print versions, not "command not found"):

```sh
docker run --rm tanka-sops:dev sops --version
docker run --rm tanka-sops:dev tk --version
docker run --rm tanka-sops:dev jb --version
docker run --rm tanka-sops:dev jq --version
docker run --rm tanka-sops:dev yq --version
```

If you change the `useradd` line, verify the runtime user is `tankasops` with
uid 999: `docker run --rm tanka-sops:dev id`.

## Release flow (read before bumping versions)

1. `.github/workflows/release.yml` runs `npx semantic-release` on every push
   to `main`. `.releaserc.json` restricts releases to the `main` branch with
   no npm publish — it only cuts a GitHub release using commit messages
   (Conventional Commits).
2. The release job authenticates with `secrets.PAT` (a personal access
   token), **not** the default `GITHUB_TOKEN`. This is deliberate: the
   `build.yml` workflow is triggered by the `release: [released]` event,
   and pushes made by the default token don't trigger downstream
   workflows. If releases stop triggering image builds, check that
   `secrets.PAT` is still set on the repo.
3. `.github/workflows/build.yml` runs only on `release: [released]`, logs
   into GHCR, and pushes to
   `ghcr.io/callepuzzle/docker-image-tanka-sops:${{ github.event.release.tag_name }}`.
   There is no `latest` tag and no multi-arch manifest.

## Conventions

- Do not introduce a `package.json`, build system, or test framework — none
  fits the repo's scope.
- Do not commit changes to `LICENSE` or `README.md` beyond typo fixes.
- Commit messages should follow Conventional Commits
  (`feat:`, `fix:`, `chore:`, …) so semantic-release can determine the next
  version on `main`.
