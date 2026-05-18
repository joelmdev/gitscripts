# About
This repository contains a collection of bash scripts to use with git. The primary script is the "gup" script, which is useful in a variety of workflows and its purpose is described below. The other scripts compose common multi-step workflows around `gup`. These scripts assume that the name of your remote is "origin", although this can easily be changed.

# Installation
Clone the repo to your folder of choice and add the aliases to your .gitconfig:

```
[alias]
# Workflow scripts (multi-step pipelines)
gup       = !C:/path/to/the/scripts/gup.sh
mnf       = !C:/path/to/the/scripts/mnf.sh
gmnf      = !C:/path/to/the/scripts/gmnf.sh
ship      = !C:/path/to/the/scripts/ship.sh
start     = !C:/path/to/the/scripts/start.sh
fco       = !C:/path/to/the/scripts/fco.sh
resync    = !C:/path/to/the/scripts/resync.sh
auto-tag  = !C:/path/to/the/scripts/auto-tag.sh
changelog = !C:/path/to/the/scripts/changelog.sh
bd        = !C:/path/to/the/scripts/bd.sh
bdd       = !C:/path/to/the/scripts/bdd.sh

# Native git aliases
co  = checkout
cob = checkout -b
f   = fetch --all --prune
sl  = stash list
sp  = stash pop
sd  = stash drop
ss  = "!f() { if [ $# -eq 0 ]; then git stash push; else git stash push -m \"$*\"; fi; }; f"
sss = "!f() { if [ $# -eq 0 ]; then git stash push -u; else git stash push -u -m \"$*\"; fi; }; f"
bm  = branch -m
```

The `ss` and `sss` aliases use a small shell wrapper so a bare message works without `-m`: `git ss "my message"` or `git ss my quick message` (all positional args are joined into the message). With no args, they stash the working tree.

It's also advisable, but not required, to enable [rerere](https://git-scm.com/blog/2010/03/08/rerere.html) to assist with conflicts:

```
[rerere]
enabled = true
```

# Usage
## gup
Gup's purpose is to easily integrate changes from the remote repository into your local tracking branches. Its result is similar to, but different from, Jason Weathered's [gup](http://jasoncodes.com/posts/gup-git-rebase) and Aanand Prasad's [git-up](https://github.com/aanand/git-up). You can use the script in 3 ways...

```
git gup [branch-name]
```

### Example
Use this command to update a main branch, or to update a feature branch that you are collaborating on but are not the owner of. This command will stash your working tree, fetch changes from the remote repository, and rebase your local commits on top of the latest changes from the remote with the `--rebase-merges` flag set. If a stash save was necessary and if the rebase was successful, it will pop the stash before completing.

```
git gup development
```

OR

```
git gup [feature-branch] [main-branch]
```

### Example
Use this command if you have a local feature branch that has not been pushed to the remote repository. This command will stash your working tree, fetch changes from the remote repository, and rebase your local commits on top of the latest changes from the remote with the `--rebase-merges` flag set for the *specified main-branch only*. It will then rebase your local feature branch onto the specified main branch. If a stash save was necessary and if the rebase was successful, it will pop the stash before completing.

```
git gup feature-addValidationToNewUserForm development
```
OR

```
git gup --update-both [feature-branch] [main-branch]
```

### Example
Use this command if you have a feature branch that has been pushed to the remote repository *and* you are the feature branch owner. This command works similar to those listed above, but it will integrate any changes from the remote main branch into your local tracking branch, then integrate changes from the remote feature branch into your local tracking branch, and finally replay the feature branch on top of the main branch. It is important to note that this command requires a force push, which the script will prompt you to perform at the end of successful rebasing using `--force-with-lease --force-if-includes` — refuses the push if someone else has pushed since you fetched, or if you haven't actually integrated remote changes you fetched. If a stash save was necessary and if the rebase was successful, it will pop the stash before completing.

```
git gup --update-both feature-addValidationToNewUserForm development
```

## mnf
Shortcut to `git merge --no-ff` command. After a successful merge it prompts whether to delete the just-merged feature branch.

To enable auto-tagging, add this either to your global config, or just the repo config where you would like to opt-in to automatic versioning:
```
git config --global release.autoTag true   # or omit --global for repo-only
```
or manually add the following to the desired .gitconfig
```
[release]
autoTag = true
```

### Example
```
git mnf [feature-branch-name] [trunk-branch-name]
```

OR

```
git mnf feature-addValidationToNewUserForm development
```

## gmnf
Composes `gup` and `mnf`: runs `gup`, and if it succeeds, runs `mnf`. Saves you from typing two commands when you've finished a feature and want to integrate trunk changes before merging.

### Example
```
git gmnf [feature-branch] [trunk-branch]
git gmnf --update-both [feature-branch] [trunk-branch]
```

## ship
The full "I'm done with this feature" pipeline: `gmnf` + `git push` + `bdd` (delete local + remote feature branch). Suppresses mnf's "delete feature branch?" prompt via the `MNF_SKIP_DELETE_PROMPT=1` env var since ship handles the cleanup itself.

### Example
```
git ship [feature-branch] [trunk-branch]
git ship --update-both [feature-branch] [trunk-branch]
```

## start
The mirror of `ship` at the *start* of a feature: `gup` the trunk, then create a new branch off it. Guarantees you never branch off a stale trunk.

### Example
```
git start [new-branch-name] [trunk-branch]
```

## fco
Fetch + checkout in one step. Useful for grabbing a teammate's freshly-pushed branch you don't have locally yet.

### Example
```
git fco [branch-name]
```

## auto-tag
Automatically creates version tags for dev, test, and prod branches after a successful mnf merge. `auto-tag` uses the currently checked out branch.

To opt-in when using `mnf.sh`:
```bash
git config --global release.autoTag true   # or omit --global for repo-only
```
How it's called: mnf runs the script automatically. You can run it yourself with

### Example
```bash
git auto-tag
```

If the required upstream tag is missing for test or prod, the script aborts so you can fix history first. If dev has no matching version history tag, an initial semver will be prompted.

### Tag formats
| Branch | Tag pattern               | Example               |
| ------ | ------------------------- | --------------------- |
| dev    | `vX.Y.Z-dev.<YYMMDD>.<n>` | `v1.4.0-dev.250603.1` |
| test   | `vX.Y.Z-rc.<YYMMDD>.<n>`  | `v1.4.0-rc.250605.1`  |
| prod   | `vX.Y.Z`                  | `v1.4.0`              |
