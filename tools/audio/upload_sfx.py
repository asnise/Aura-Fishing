"""Upload SFX files in assets/sfx/ (*.mp3, *.wav, *.ogg) to Roblox as Audio (Open Cloud),
then write the ids to assets/sfx/ids.json and update src/shared/Config/Sounds.luau.

Run it in PowerShell / Terminal (asks for your API key; never saved or printed):
    python -I tools/audio/upload_sfx.py --user <yourUserId>      (or --group <groupId>)
Options: --only ui_click,cast   --dry-run   --redo (with --only: upload again even if it has an id,
         use after replacing the file in assets/sfx; Sounds.luau gets the new id)
Resumable: files that already have an id in ids.json are skipped.
"""
import getpass
import glob
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX = os.path.join(ROOT, "assets", "sfx")
IDS = os.path.join(SFX, "ids.json")
SOUNDS_CFG = os.path.join(ROOT, "src", "shared", "Config", "Sounds.luau")
API = "https://apis.roblox.com/assets/v1/"

MIME_TYPES = {
    ".mp3": "audio/mpeg",
    ".wav": "audio/wav",
    ".ogg": "audio/ogg",
}


def arg(name):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else None


def request(method, url, key, body=None, headers=None):
    req = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": key, **(headers or {})})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:300]}") from None


def upload(path, name, creator, key):
    ext = os.path.splitext(path)[1].lower()
    mime = MIME_TYPES.get(ext, "audio/mpeg")
    boundary = uuid.uuid4().hex
    meta = {
        "assetType": "Audio",
        "displayName": f"AF_{name}"[:50],
        "description": "Aura Fishing SFX",
        "creationContext": {"creator": creator},
    }
    data = open(path, "rb").read()
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(meta)}\r\n"
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{os.path.basename(path)}\"\r\n"
        f"Content-Type: {mime}\r\n\r\n"
    ).encode() + data + f"\r\n--{boundary}--\r\n".encode()

    op = request("POST", API + "assets", key, body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})
    for _ in range(90):
        if op.get("done"):
            res = op.get("response", {})
            if "assetId" in res:
                return res["assetId"]
            raise RuntimeError(f"upload finished without assetId: {json.dumps(op)[:300]}")
        time.sleep(3)
        op = request("GET", API + op["path"], key)
    raise RuntimeError("timed out waiting for the upload operation")


def update_sounds_config(ids):
    if not os.path.exists(SOUNDS_CFG):
        return
    text = open(SOUNDS_CFG, "r", encoding="utf-8").read()
    for name, aid in ids.items():
        # replaces the placeholder or an older id, so a re-uploaded file takes over
        text = re.sub(rf'({re.escape(name)} = {{ Id = )(?:PLACEHOLDER|"rbxassetid://\d+")', rf'\g<1>"rbxassetid://{aid}"', text)
    open(SOUNDS_CFG, "w", encoding="utf-8", newline="\n").write(text)


def main():
    user, group = arg("--user"), arg("--group")
    if user and group:
        print(__doc__)
        sys.exit(2)
    ids = json.load(open(IDS, encoding="utf-8")) if os.path.exists(IDS) else {}
    only = set(arg("--only").split(",")) if arg("--only") else None

    # Scan all audio formats in assets/sfx
    files = []
    for ext in ("*.mp3", "*.wav", "*.ogg"):
        files.extend(glob.glob(os.path.join(SFX, ext)))
    files = sorted(files)

    todo = []
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        redo = "--redo" in sys.argv and (not only or name in only)
        if (name not in ids or redo) and (not only or name in only):
            todo.append(f)

    print(f"{len(todo)} SFX file(s) to upload")
    if "--dry-run" in sys.argv or not todo:
        for f in todo:
            print("  ", os.path.basename(f))
        return

    if not (user or group):
        print("specify --user <UserId> or --group <GroupId>")
        sys.exit(2)

    creator = {"userId": user} if user else {"groupId": group}
    key = getpass.getpass("Roblox Open Cloud API Key (Assets Read+Write): ").strip()
    if not key:
        print("aborted (no key)")
        sys.exit(1)

    for i, path in enumerate(todo):
        name = os.path.splitext(os.path.basename(path))[0]
        print(f"[{i+1}/{len(todo)}] uploading {os.path.basename(path)} ({name})...")
        try:
            aid = upload(path, name, creator, key)
            ids[name] = aid
            with open(IDS, "w", encoding="utf-8", newline="\n") as fp:
                json.dump(ids, fp, indent=2, sort_keys=True)
            update_sounds_config({name: aid})
            print(f"  -> rbxassetid://{aid}")
        except Exception as e:
            print(f"  FAILED: {e}")
            break

    print(f"Done. {len(ids)}/{len(files)} total SFX mapped in {IDS}")


if __name__ == "__main__":
    main()
