# logos-ecodev-catalog

The **Logos Eco Dev sample-apps catalog** — one repository URL that
installs the sample apps built and actively maintained by the Logos
Ecosystem Development team.

```text
https://raw.githubusercontent.com/logos-co/logos-ecodev-catalog/main/logos-repo.json
```

Paste it into **Logos Basecamp → Settings → Repositories → Add
repository**, then install from the App Manager.

Built from
[`logos-co/logos-modules-release-base`](https://github.com/logos-co/logos-modules-release-base)
(see [logos-co/ecosystem#157](https://github.com/logos-co/ecosystem/issues/157)):
this repo holds the submodules and catalog metadata; all release
machinery lives in the versioned, reusable
[`logos-co/logos-modules-release-action`](https://github.com/logos-co/logos-modules-release-action).
Per that issue's direction, the app list is the aggregate of the team's
individual catalogs, keeping only apps that are actively maintained.

## What's in the catalog

| App | What it does | Maintainer | Source |
| --- | --- | --- | --- |
| Stash | Store files in Logos Storage, get a CID back | Alisher | [`xAlisher/stash-basecamp`](https://github.com/xAlisher/stash-basecamp) |
| Beacon | Inscribe CIDs on the Logos blockchain | Alisher | [`xAlisher/beacon-basecamp`](https://github.com/xAlisher/beacon-basecamp) |
| Keeper | Preserve Internet Archive collections to Storage + chain | Alisher | [`xAlisher/keeper-basecamp`](https://github.com/xAlisher/keeper-basecamp) |
| Cord | Subscribe to zone channels, discover inscriptions | Alisher | [`xAlisher/cord-basecamp`](https://github.com/xAlisher/cord-basecamp) |
| Keycard | Keycard smartcard authentication | Alisher | [`xAlisher/keycard-basecamp`](https://github.com/xAlisher/keycard-basecamp) |
| Receiver | Listen-only decentralised radio over Logos Messaging | Alisher | [`xAlisher/receiver-basecamp`](https://github.com/xAlisher/receiver-basecamp) |
| IA | Sovereign archive follower & preservation | Alisher | [`xAlisher/ia-basecamp`](https://github.com/xAlisher/ia-basecamp) |
| Soulseek | Soulseek music search & playlists (core + UI) | Alisher / Dario | [`xAlisher/soulseek-basecamp`](https://github.com/xAlisher/soulseek-basecamp), [`xAlisher/soulseek-ui`](https://github.com/xAlisher/soulseek-ui) |
| Hello | Minimal universal module + QML UI; proves the release path | Dario | [`dlipicar/logos-hello-module`](https://github.com/dlipicar/logos-hello-module), [`dlipicar/logos-hello-ui`](https://github.com/dlipicar/logos-hello-ui) |

### Not (yet) included

- **LEZ Faucet** ([`logos-co/lez-faucet`](https://github.com/logos-co/lez-faucet))
  and **ETH ↔ LEZ Atomic Swaps**
  ([`logos-co/eth-lez-atomic-swaps`](https://github.com/logos-co/eth-lez-atomic-swaps))
  — Danish's apps. Both are *multi-module repos* (`faucet-module/` +
  `faucet-ui/`, `swap-module/` + `swap-ui/`, each with its own
  `metadata.json` in a subdirectory). The `@v1` release action can only
  build a module whose `metadata.json` sits at the root of a submodule:
  its checkout step runs
  `git submodule update --init --recursive -- <module_path>`, and a
  `module_path` pointing *inside* a submodule
  (`submodules/lez-faucet/faucet-module`) fails with
  `pathspec did not match`. Until the action grows subdirectory support
  (or the apps split into one-repo-per-module), install them from
  Danish's individual catalog:
  `https://logos.substratestudios.xyz/logos-repo.json`.
- **Booth** ([`xAlisher/booth-basecamp`](https://github.com/xAlisher/booth-basecamp),
  formerly `radio-basecamp`) — same multi-module layout
  (`radio_module/` + `radio_ui/`), same blocker as above.
- **Node Remote** ([`xAlisher/node-remote`](https://github.com/xAlisher/node-remote))
  — no root `metadata.json`; it's a multi-component repo
  (`node-remote-bc/`, `node-remote-android/`), not a buildable module at
  its root.
- **`docs-logos`, `logos-blockchain-module`/`-ui`,
  `logos-zone-sequencer-module`** — present in individual catalogs but
  they are infra forks / docs, not eco dev sample apps.

## Adding your app (team members)

```bash
git clone https://github.com/logos-co/logos-ecodev-catalog
cd logos-ecodev-catalog
./scripts/add-module.sh https://github.com/<you>/<your-app-repo>   # [name] [branch] optional
git add -A && git commit -m "Add <your-app-repo>" && git push
```

`add-module.sh` registers the submodule **and** generates its
per-module release workflow. Requirements for the app repo: a
`metadata.json` at its root (name + version) and a Nix flake the
release action can build. One module per repo — core and UI plugins
each get their own submodule entry.

Removing an app is the reverse: `git rm submodules/<name>`, delete
`.github/workflows/release-<name>.yml`, then run **Unpublish** from the
Actions tab (with `dry_run: true` first) to drop its releases from the
index.

## Publishing

From the **Actions** tab run **Release all modules** (or an individual
**Release \<module\>**) — or, from a terminal,
`./scripts/catalog.sh release-all`. The action builds each `.lgx`,
verifies it, cuts a `<module>-v<version>` GitHub release, and rolls
everything up into the rolling `index` release that clients read
(`releases/download/index/index.json` — the `indexUrl` in
`logos-repo.json`).

A new version ships when you bump the submodule pointer (which moves
its `metadata.json#version`) and re-run its workflow; re-running an
unchanged submodule is a fast no-op. Both release workflows take a
**Force build** toggle to rebuild and replace an already-published
version.

## Layout

```
.
├── logos-repo.json                       # catalog metadata clients read
├── .gitmodules                           # submodule declarations
├── submodules/                           # one git submodule per module
├── scripts/
│   ├── add-module.sh                     # add a submodule + generate its workflow
│   └── catalog.sh                        # run the catalog workflows via `gh` (no Actions tab)
└── .github/workflows/
    ├── _release-module.yml               # signing config — the ONE place to edit it
    ├── release-module.yml.template       # per-module workflow template (don't run; it's a template)
    ├── release-<module>.yml              # one per app, generated by add-module.sh
    ├── release-all.yml                   # umbrella; discovers modules from .gitmodules
    ├── rebuild-index.yml                 # rebuilds index.json after each release
    └── unpublish.yml                     # manually remove a module / version from the catalog
```

### Workflow architecture

Two-tier reusable workflows so the signing pipeline lives in exactly
one place:

- **`_release-module.yml`** — local *private* reusable workflow
  (`workflow_call` only). Calls
  `logos-co/logos-modules-release-action/.github/workflows/release.yml@v1`
  with this catalog's signing configuration.
- **`release-<module>.yml`** — one per module, generated by
  `add-module.sh`. Each just passes `module_path: submodules/<repo>` to
  `_release-module.yml`.
- **`release-all.yml`** — umbrella. Discovers the module list from
  `.gitmodules` at run time and fans out per module in parallel.
- **`rebuild-index.yml`** — thin passthrough to the action's
  index-rebuilder. Auto-triggered after each release; also runs on a
  6-hourly catch-up schedule.
- **`unpublish.yml`** — manual (Actions tab). Removes a whole module or
  one specific version, then rebuilds the index. **Run with
  `dry_run: true` first** — deletion is irreversible.

To change signing for the whole catalog, edit **`_release-module.yml`
only** — the per-module callers and the umbrella never need touching.

## Signing

Publishes **unsigned** for now (`signing_mode: none`, matching the
empty `trustedSigners` in `logos-repo.json`). To turn on signing,
follow the inline instructions at the top of
[`.github/workflows/_release-module.yml`](.github/workflows/_release-module.yml):

| Mode | What runs | Where the key lives |
|---|---|---|
| `none` (current) | nothing | n/a — unsigned releases |
| `inline` | `lgx sign` in CI | `LOGOS_SIGNING_KEY` Actions secret (Ed25519 JWK) |
| `external` | your `signing_command` | anywhere (Jenkins / HSM / hardware token) |

For `inline`, also put the matching public DID under `trustedSigners`
in `logos-repo.json` so clients trust the signature.

## Notes for cloning

`.gitmodules` is committed but submodule working trees are not — after
cloning, run:

```bash
git submodule update --init --recursive
```
