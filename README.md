# Vanish - anonymous temporary chats for Ubuntu Touch (Lomiri)

QML client. No accounts, text only, any number of people per chat,
every chat vanishes 24 h after creation unless a member keeps a read-only copy **on their own device**.

## 2. Run / build the client

```bash
pip3 install clickable-ut        # once
clickable desktop                # run on your computer
clickable                        # build + install + launch on a connected device
clickable build --arch arm64     # produce the .click (in build/…/app)
clickable review                 # lint before OpenStore upload
```

## 3. How it works
* **Identity.** Every chat gets a fresh random member UUID generated on the phone; the chosen display name is
  per chat (spaces/emoji fine, `@` removed). Names are made unique inside a chat (`Sam`, `Sam (2)`).
  Chats can't be linked to each other server-side; only the device id in `Users` is logged for statistics.
* **Colours.** The server gives each member a random hue far from those already used in that chat.
* **Read by.** Each member has a read pointer; a message is "read by" everyone whose pointer is >= its number.
  Tap *Read by N* to see who has / hasn't.
* **Keep.** Messages are cached locally while a chat is active. Tapping ★ Keep marks it; after expiry it stays as a
  read-only local copy. Not kept = removed locally when it expires.
* **Mute / pin / leave** are local (leave also tells the server so you stop appearing as a member).
* **Mentions.** `@name` of current members is highlighted; typing `@` offers a member picker.
* **Links** (`http(s)://…`, `www.…`) are underlined and coloured; tapping opens the browser.
* **Public tab.** Chats created with "List in Public chats" appear for everyone, sorted by member count.

## 4. Known limits
* **Notifications only while the app is open** (in-app banner + unread badges). A sheets-only backend has no way to
  wake a closed app; real push would need a push server / UBports push token.
* Polling: 2.5 s for the open chat, 15 s for the rest, so
  this suits hundreds, not tens of thousands, of simultaneous users. Raise the intervals in `lib/Store.qml` if needed.
* Edit the links in `qml/js/config.js` (source repo, feedback site, donation links) - they are placeholders.

## 5. Release pipelines (GitLab and GitHub)

Both build `vanish.vitalsoft_amd64.click`, `_arm64.click` and `_armhf.click` with Clickable's
`clickable/ci-20.04-<arch>` Docker images and share `ci/prepare.sh` + `ci/build-click.sh`.

| | GitLab (`.gitlab-ci.yml`) | GitHub (`.github/workflows/release.yml`) |
|---|---|---|
| Every branch push | 3 job artifacts (30 days) | 3 workflow artifacts |
| Tag `vX.Y.Z` | uploads to the Package Registry + creates a Release with the 3 files | creates a Release with the 3 files |
| Backend URL | CI/CD variable `VANISH_API_URL` (Protected; can't be Masked, the URL has `_` and `-`) | secret `VANISH_API_URL` |

Release steps: bump `version` in `manifest.json.in`, commit, then `git tag v0.2.0 && git push --tags`.
The pipeline fails if the tag and manifest version differ, or if `VANISH_API_URL` is missing on a tag.
The URL is injected into `qml/js/config.js` at build time so it never sits in the repo, but it is plain text
inside the finished `.click` (a click is a zip), so treat the URL as obscure, not secret.

The app is pure QML, so a single `all` click would also run everywhere (that is what a local `clickable build` now
produces). The three per-arch files exist because you asked for them; drop two matrix entries to publish just one.
