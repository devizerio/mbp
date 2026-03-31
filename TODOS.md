# TODOs

## Mark `version-check` as required in GitHub branch protection

**Why:** The CI check runs on every PR but doesn't block merging until it's marked as a required status check. Without this, developers can still merge PRs that skip the version bump.

**How:** After the version-check workflow PR is merged, go to GitHub → Settings → Branches → Branch protection rules → main → Require status checks to pass → add `Version Bump Check`.

**Added:** 2026-03-27

## Consider module registry instead of NN-name.sh glob resolution

**Why:** Module names are resolved by globbing `modules/NN-<name>.sh`. If someone adds a module with the wrong numeric prefix or a naming conflict, the glob silently picks the wrong file. A registry (e.g., an associative array in bin/mbp mapping names to paths) would be explicit and fail loudly.

**How:** Replace `mbp_resolve_module_path()` glob with a declared mapping in bin/mbp. Could extend `MBP_MODULE_DESC` to include paths.

**Added:** 2026-03-31
