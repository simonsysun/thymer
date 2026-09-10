# Contributing

Ideas and bug reports are welcome in [Issues](https://github.com/simonsysun/thymer/issues).
For UI bugs, mention the macOS version, build number, and the steps that led to
the problem. Remove personal task names and unrelated screen content before
sharing a screenshot. Do not attach your records database.

For build and test instructions, see [NATIVE.md](NATIVE.md). Use independent test
data and preserve the recording rules when changing the timer.

Keep `README.md` and `README.zh.md` in sync. Describe current features accurately
and keep future plans broad. The first release is pending final hands-on checks.

Before submitting changes, run `python3 scripts/check-public-files.py`. Local
handoffs, screenshots of personal data, credentials, and databases must stay out
of public commits. This check is a guardrail, not a complete security audit.
