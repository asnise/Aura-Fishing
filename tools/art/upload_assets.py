"""Upload every UI image in assets/catalog.json (assets/ui-global + assets/art) to Roblox with Open Cloud,
then write the ids back (catalog.json -> UIAssets.luau via sync_ui_assets.py).

Run it yourself in a terminal (it asks for your API key; the key is never saved or printed):
    python -I tools/art/upload_assets.py --user <yourUserId>      (or --group <groupId>)
Options: --only fish/BubbleCarp,icon_lock   --dry-run
Resumable: assets that already have an id in catalog.json are skipped.

API key: create.roblox.com -> Open Cloud -> API Keys -> Create: add API system "Assets" with Read + Write,
accepted IP 0.0.0.0/0 (or yours). Uploads are Decals; Roblox moderates them (a few minutes each).
Next step: node tools/ui/resolve_decals.mjs  (Studio: turns decal ids into the image ids UI needs).
"""
import getpass
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CAT = os.path.join(ROOT, "assets", "catalog.json")
API = "https://apis.roblox.com/assets/v1/"


def arg(name):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else None


def request(method, url, key, body=None, headers=None):
    req = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": key, **(headers or {})})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:300]
        raise RuntimeError(f"HTTP {e.code}: {detail}") from None


def upload(path, name, creator, key):
    boundary = uuid.uuid4().hex
    meta = {
        "assetType": "Decal",
        "displayName": name[:50],
        "description": "Aura Fishing UI asset",
        "creationContext": {"creator": creator},
    }
    data = open(path, "rb").read()
    ctype = mimetypes.guess_type(path)[0] or "image/png"
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(meta)}\r\n"
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{os.path.basename(path)}\"\r\n"
        f"Content-Type: {ctype}\r\n\r\n"
    ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
    op = request("POST", API + "assets", key, body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})
    for _ in range(60):
        if op.get("done"):
            res = op.get("response", {})
            if "assetId" in res:
                return res["assetId"]
            raise RuntimeError(f"upload finished without assetId: {json.dumps(op)[:300]}")
        time.sleep(2)
        op = request("GET", API + op["path"], key)
    raise RuntimeError("timed out waiting for the upload operation")


def main():
    user, group = arg("--user"), arg("--group")
    if user and group:
        print(__doc__)
        sys.exit(2)
    if not (user or group) and "--dry-run" not in sys.argv:
        print("Your Roblox User ID = the number in your profile URL: roblox.com/users/<UserId>/profile")
        user = input("Roblox User ID: ").strip()
        if not user.isdigit():
            print("User ID must be a number")
            sys.exit(2)
    user = user or "0"
    creator = {"userId": str(user)} if user else {"groupId": str(group)}
    only = set(arg("--only").split(",")) if arg("--only") else None
    cat = json.load(open(CAT, encoding="utf-8"))
    todo = [(g, k, v) for g in ("global", "art") for k, v in cat[g].items() if not v.get("rbxassetid") and (not only or k in only)]
    print(f"{len(todo)} images to upload")
    if "--dry-run" in sys.argv or not todo:
        for _, k, v in todo:
            print("  ", k, v["file"])
        return
    key = os.environ.get("ROBLOX_API_KEY") or getpass.getpass("Roblox Open Cloud API key (hidden): ").strip()
    done = 0
    for g, k, v in todo:
        path = os.path.join(ROOT, v["file"])
        try:
            aid = upload(path, k.replace("/", "_"), creator, key)
        except Exception as e:  # keep going; re-run later resumes
            print(f"  FAIL {k}: {e}")
            if "HTTP 401" in str(e) or "HTTP 403" in str(e):
                print("  -> check the API key permissions (Assets: Read + Write) and the creator id")
                break
            continue
        cat[g][k]["rbxassetid"] = f"rbxassetid://{aid}"
        cat[g][k]["decal"] = True  # resolve_decals.mjs swaps in the image id
        json.dump(cat, open(CAT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)  # save after each one
        done += 1
        print(f"  ok {k} -> decal {aid}  ({done}/{len(todo)})")
        time.sleep(1.1)  # stay under the Open Cloud rate limit
    os.system(f'python -I "{os.path.join(ROOT, "tools", "art", "sync_ui_assets.py")}"')
    print("next: node tools/ui/resolve_decals.mjs   (with Studio open)")


if __name__ == "__main__":
    main()
