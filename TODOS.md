# TODOs

## Mark `version-check` as required in GitHub branch protection

**Why:** The CI check runs on every PR but doesn't block merging until it's marked as a required status check. Without this, developers can still merge PRs that skip the version bump.

**How:** After the version-check workflow PR is merged, go to GitHub → Settings → Branches → Branch protection rules → main → Require status checks to pass → add `Version Bump Check`.

**Added:** 2026-03-27
