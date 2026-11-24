# Vanish — anonymous temporary chats for Ubuntu Touch (Lomiri)

QML client + Google Sheets / Apps Script backend. No accounts, text only, any number of people per chat,
every chat vanishes 24 h after creation unless a member keeps a read-only copy **on their own device**.

```
qml/            Lomiri QML client (Main.qml, pages/, components/, lib/ singletons, js/)
backend/        Code.gs (public API + expiry) and Admin.gs (admin API for the future panel)
clickable.yaml  pure-qml-cmake build, framework ubuntu-sdk-20.04
```

## 1. Backend (5 minutes)

1. Create a new Google Sheet (any name). **Extensions > Apps Script**.
2. Paste `backend/Code.gs` and `backend/Admin.gs` as two files.
3. Select **`setup`** in the function drop-down and **Run** (authorise). It creates the `Meta` and `Users`
   sheets, the master feedback chat (code `FEEDBACK`), a 10-minute expiry trigger and an `ADMIN_KEY`
   (Project Settings > Script properties — keep it secret).
4. **Deploy > New deployment > Web app** — Execute as **Me**, access **Anyone**. Copy the `/exec` URL.
5. Re-deploy (Manage deployments > pencil > Version: New version > Deploy) after every script change, otherwise the live URL keeps running the old code.

Put the URL in `qml/js/config.js` (`API_URL`) before building, or paste it in the app under
**Settings > Backend** (stored locally, overrides the default).

### Sheets
| Sheet | Purpose |
|---|---|
| `Meta` | One row per chat, never deleted: id, code, name, public flag, status (`active`/`expired`), created/expires/expired timestamps (ms), message count, member count, `hold`, creator device, members JSON (name, colour, read pointer) |
| `Users` | One row per device (first/last seen, sessions, chats created/joined, banned) — analytics only |
| `c_<chatId>` | Messages of one live chat. Deleted at expiry unless `hold` is TRUE |

### Admin API
Same URL, **POST** JSON (`Content-Type: text/plain`; the phone app uses GET, which refuses `admin`):
`{"action":"admin","key":"<ADMIN_KEY>","op":"<op>", ...}`

`stats`, `listChats {status,q,limit,offset}`, `getChat {chatId}` (full export incl. names, for lawful requests),
`hold {chatId,hold}` (**set before expiry**, otherwise the sheet is already gone), `expireNow`, `purge`,
`setPublic`, `rename`, `post {chatId,text}` (shows as an admin notice), `prune {chatId,keep}`,
`listUsers`, `ban {deviceId,banned}`, `feedback {after}` (read the master chat).

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
* Polling: 2.5 s for the open chat, 15 s for the rest. Apps Script has daily quota and concurrency limits, so
  this suits hundreds, not tens of thousands, of simultaneous users. Raise the intervals in `lib/Store.qml` if needed.
* Anonymity is from other users and from accounts, not from the backend owner: the admin can read live chats.
* Edit the links in `qml/js/config.js` (source repo, feedback site, donation links) — they are placeholders.

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
