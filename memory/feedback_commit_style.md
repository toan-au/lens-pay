---
name: feedback_commit_style
description: No Claude co-author signature in commits or PRs, keep messages sounding human
metadata:
  type: feedback
---

Never sign commits or PR descriptions with Claude attribution ("Generated with Claude Code", "Co-Authored-By: Claude", etc.). Keep commit messages and PR descriptions sounding like they were written by the developer. Natural, direct language — not AI assistant prose.

**Why:** User explicitly requested this multiple times. Attribution feels inauthentic and is unwanted.

**How to apply:** Omit all Claude signatures from git commits and GitHub PR descriptions. Write in first person or plain technical prose as if the developer wrote it themselves.
