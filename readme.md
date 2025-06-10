# About
This repository contains a collection of bash scripts to use with git. The primary script is the "gup" script, which is useful in a variety of workflows and its purpose is described below. Many of the other scripts are simply shorthand aliases of single commands. These scripts assume that the name of your remote is "origin", although this can easily be changed.

# Installation
Clone the repo to your folder of choice and add the aliases to your .gitconfig:

```
[alias]
auto-tag = !C:/path/to/the/scripts/auto-tag.sh
gup = !C:/path/to/the/scripts/gup.sh
changelog = !C:/path/to/the/scripts/changelog.sh
mnf = !C:/path/to/the/scripts/mnf.sh
co = !C:/path/to/the/scripts/co.sh
cob = !C:/path/to/the/scripts/cob.sh
f = !C:/path/to/the/scripts/f.sh
resync = !C:/path/to/the/scripts/resync.sh
ss = !C:/path/to/the/scripts/ss.sh
sss = !C:/path/to/the/scripts/sss.sh
sp = !C:/path/to/the/scripts/sp.sh
sl = !C:/path/to/the/scripts/sl.sh
sd = !C:/path/to/the/scripts/sd.sh
bd = !C:/path/to/the/scripts/bd.sh
bdd = !C:/path/to/the/scripts/bdd.sh
bm = !C:/path/to/the/scripts/bm.sh
```

It's also advisable, but not required, to enable [rerere](https://git-scm.com/blog/2010/03/08/rerere.html) to assist with conflicts:

```
[rerere]
enabled = true
```

# Usage
## gup
Gup's purpose is to easily integrate changes from the remote repository into your local tracking branches. It's result is similar to, but different from, Jason Weathered's [gup](http://jasoncodes.com/posts/gup-git-rebase) and Aanand Prasad's [git-up](https://github.com/aanand/git-up). You can use the script in 3 ways...

```
git gup [branch-name]
```

### Example
Use this command to update a main branch, or to update a feature branch that you are collaborating on but are not the owner of. This command will stash your working tree, fetch changes from the remote repository and rebase your local commits on top of the latest changes from the remote with the --preserve-merges flag set. If a stash save was necessary and if the rebase was successful, it will pop the stash before completing. 

```
git gup development
```

OR

```
git gup [feature-branch] [main-branch]
```

### Example
Use this command if you have a local feature branch that has not been pushed to the remote repository. This command will stash your working tree, fetch changes from the remote repository, and rebase your local commits on top of the latest changes from the remote with the --preserve-merges flag set for the *specified main-branch only*. It will then rebase your local feature branch onto the specified main branch. If a stash save was necessary and if the rebase was successful, it will pop the stash before completing.

```
git gup feature-addValidationToNewUserForm development
```
OR 

```
git gup --update-both [feature-branch] [main-branch]
```

### Example
Use this command if you have a feature branch that has been pushed to the remote repository *and* you are the feature branch owner. This command works similar to those listed above, but it will integrate any changes from the remote main branch into your local tracking branch, then integrate changes from the remote feature branch into your local tracking branch, and finally replay the feature branch on top of the main branch. It is important to note that this command requires a git push with the --force flag set, which the script will prompt you to perform at the end of successful rebasing. If the script is unsuccessful, you will need to do this yourself. If a stash save was necessary and if the rebase was successful, it will pop the stash before completing

```
git gup --update-both feature-addValidationToNewUserForm development
```

## mnf
Shortcut to `git merge --no-ff` command.

To enable auto-tagging, add this either to your global config, or just the repo config where you would like to opt-in to automatic versioning
run `git config --global release.autoTag true` with or without --global depending on where you want to opt-in to this behavior
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

## auto-tag
Automatically creates version tags for dev, test, and prod branches after a successful mnf merge. `auto-tag` uses the currently checked out branch.

To opt-in when using `mnf.sh`:
```bash
git config --global release.autoTag true   # or omit --global for repo-only
```
How it’s called: mnf runs the script automatically. You can run it yourself with

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
