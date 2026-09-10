#!/usr/bin/env python3
"""Check publishable files or reachable Git history without printing secret values."""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PATTERNS = {
    "personal home path": re.compile(rb"/(?:Users|home)/[a-zA-Z0-9_.-]+/"),
    "private key": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "GitHub token": re.compile(rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})\b"),
    "provider key": re.compile(rb"\b(?:sk-(?:proj-|ant-)?[A-Za-z0-9_-]{24,}|AIza[0-9A-Za-z_-]{30,}|AKIA[0-9A-Z]{16})\b"),
    "credential in URL": re.compile(rb"https?://[^\s/@:]+:[^\s/@]+@"),
}

def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)

def private_path(name):
    p = pathlib.PurePosixPath(name)
    return (name.startswith(("docs/handoff/", "local/", ".codex/", ".agents/"))
            or (p.name.startswith(".env") and p.name != ".env.example")
            or re.search(r"\.(?:sqlite|db)(?:-(?:wal|shm|journal))?$", name)
            or any(part.endswith(".app") for part in p.parts))

def inspect(label, data):
    findings = []
    for kind, pattern in PATTERNS.items():
        for match in pattern.finditer(data):
            line = data.count(b"\n", 0, match.start()) + 1
            findings.append(f"{label}:{line}: {kind}")
    return findings

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--history", action="store_true", help="scan all locally reachable Git commits")
    args = parser.parse_args()
    findings, count = [], 0
    if args.history:
        seen = set()
        for commit in git("rev-list", "--all").decode().splitlines():
            for row in git("ls-tree", "-r", "-z", commit).split(b"\0"):
                if not row:
                    continue
                meta, rawname = row.split(b"\t", 1)
                _, kind, oid = meta.split()
                name = rawname.decode()
                if private_path(name):
                    findings.append(f"{commit[:12]}:{name}: private file in history")
                if kind == b"blob" and oid not in seen:
                    seen.add(oid)
                    findings.extend(inspect(f"{commit[:12]}:{name}", git("cat-file", "blob", oid.decode())))
                    count += 1
    else:
        names = set(git("ls-files", "-z", "--cached", "--others", "--exclude-standard").split(b"\0"))
        for rawname in sorted(names):
            if not rawname:
                continue
            name = rawname.decode()
            path = ROOT / name
            if not path.exists():  # moved/deleted worktree files are not publication candidates
                continue
            if private_path(name):
                findings.append(f"{name}: private file is publishable")
            if path.is_symlink():
                findings.append(f"{name}: review symlink before publishing")
            elif path.is_file():
                findings.extend(inspect(name, path.read_bytes()))
                count += 1
    for finding in findings:
        print(finding)
    print(f"Checked {count} files/blobs; {len(findings)} findings. Values are redacted.")
    return bool(findings)

if __name__ == "__main__":
    sys.exit(main())
