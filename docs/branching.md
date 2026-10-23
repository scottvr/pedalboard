# Branches, worktrees and the road to upstream (proposed 2026-10-23)

Four forks, four upstreams that move on their own cadence, and our own merges that do not
map one to one onto the PRs we want to open. This is the shape proposed for it; adopt it
when the next PRs (tracks A, J, K) open, and revise here. Nothing below is in force until
the "Adopted" line at the end says so.

## What happens today, by hand

Each upstream track is a worktree on its own branch off `upstream/main` (`cli-track-a`,
`targets-track-j`, ...), which is already the PR-per-branch half of the model. The pedal is
built from `cli-pedal-43b` and `targets-pedal-43b`: detached worktrees where the tracks the
pedal needs were applied by copy and left uncommitted. That is an integration branch
without the branch: it cannot be pushed for backup, rebuilt after a rebase, or told apart
from a bench edit. The three main clones sit on `lafvin-composed-display`, which started as
a topic branch (tracks B and C) and became the place everything else was stacked.

## The model

Per fork, three kinds of branch:

1. **`main` mirrors `upstream/main`.** Fast-forward only, never committed to. `git fetch
   upstream && git merge --ff-only upstream/main`. Everything is measured against it.
2. **One topic branch per intended upstream PR**, named for the change, not for us
   (`composed-no-audio-chip`, `gt911-external-task-stack`), based on `upstream/main`. The
   branch *is* the PR: no separate `ready-for-upstream` branch, no cherry-pick promotion,
   which would mint duplicate commits and a second history to rebase. Rebase onto
   `upstream/main` before opening and whenever upstream moves under it. When a topic depends
   on another (Gea's convention that a shared component lives with the first board that
   implements it makes this common: board B's PR needs board A's component), base it on that
   topic branch. GitHub shows the stacked PR with both diffs until A merges, which is what
   track G's "sits on #5" was; once A lands, `git rebase --onto upstream/main A B` and the
   PR shrinks to its own change. Keep stacks two deep; a third level waits.
3. **One integration branch per thing we build**, named for the thing (`pedal-43b`,
   `lafvin`, later `pedal-p4`): `upstream/main` plus `git merge` of every topic branch that
   build needs, plus nothing else. It is rebuilt, never developed on: a fix found on the
   bench is committed on its topic branch and the integration branch re-merged (or reset to
   `upstream/main` and re-merged from scratch, which is cheap and keeps it honest). This is
   the branch to push to the fork for backup and for building from another machine, and
   the one `docs/build-environment.md`'s bench commands point at. It never becomes a PR.

The git config's fast-forward-only merge setting is the guard for the topic branches: a
topic can never pick up a merge commit by accident, so a PR opened from one is always
linear. The integration branches are the one place merge commits belong, and they are made
with an explicit `git merge --no-ff <topic>`, which overrides the setting for that merge
only.

Worktrees follow the branches: one per topic in flight, one per integration branch, named
`<repo>-<branch>`; `git worktree list` is the inventory, and `.gitignore` covers them by
pattern. Remove a topic's worktree when its PR merges; the integration branch then drops
the merge on its next rebuild because the change is in `upstream/main`.

The pedal fork is the same picture with different names: `lavfin-kit-notes` is its
integration branch today (fork commits plus notes), and the upstream PRs (UAC1, WPA3, the
4.3B board, the footswitch setting) each want a topic branch cut from `upstream/main` with
the relevant commits cherry-picked once, at cut time, from the integration line. For
coyopedal that one-time cherry-pick is unavoidable because the history was written the
other way round; for the Gea forks the topic branches already exist, so nothing needs
picking.

## If upstream declines

`README.md` says the fallback is to merge the branches into the forks' `main` and
maintain divergent versions. Better: keep `main` the mirror, and let the integration
branch be the divergent line (`pedal-43b` and friends, or one `scottvr` branch merging all
of them). Syncing with upstream then stays a fast-forward of `main` and a re-merge, instead
of a conflict-prone merge into a `main` that no longer matches anything upstream.

## Cadence

- Upstream moves: fetch, fast-forward `main`, rebase the open topics, rebuild the
  integration branches. Do it before opening a PR and after upstream merges one of ours.
- Our own PRs on the forks (review of our own work from another machine, or a record): open
  them from the topic branch onto the integration branch, not onto `main`, so `main` keeps
  mirroring. They are optional; the integration branch's merge commits already record the
  same thing.
- Backup cadence is "push the integration branch when it builds"; topic branches go up when
  they are worth a PR, since the integration branch holds their commits already.

## Adopted

2026-10-23. Done that day: `main` fast-forwarded to `upstream/main` in cli, targets and core
(none had commits of its own); `pedal-43b` created in cli and targets at the bench chain's
tip (the gift board, G, H, I as re-rolled commits) with A, J and K merged in, and checked out
in `cli-pedal-43b/` and `targets-pedal-43b/` in place of the detached copies, after a diff
showed the merged tree equal to the bench tree apart from the topics' new tests and two
comment lines the topics' newer base had changed; `.gitignore` covers worktrees by pattern.
Later the same day, on request: every topic rebased onto the upstream main of 2026-10-23
(A and J clean; K conflicted because upstream `dfeb417` had landed the same change, so K was
dropped); H and I cut as topics `source-walk-prune-gea-state` and `rgb-flush-odometer-read`
by cherry-picking the bench chain's commits onto upstream main; the three PR branches
rebased and force-pushed to the fork with `--force-with-lease` (all three PRs mergeable
again); both `pedal-43b` branches reset to upstream main and re-merged from the rebased
topics. First real exercise of the model: the rebuild took one command per repo.
The pedal fork got its `upstream` remote the same evening, `main` fast-forwarded, and
upstream's three new commits merged into `lavfin-kit-notes` with `--no-ff` (one doc
conflict, both sides kept); as the pedal's integration branch it is merged, not rebased,
since its history is pushed and read.
Not done: `lafvin-composed-display` still carries B, C, H and I as direct commits and stays
checked out in the three main clones until B and C are cut as topics; `core-main/` stays a
detached worktree at the upstream main the bench built with (core's `main` is 54 commits
newer). Upstream moved under every topic on 2026-10-23: rebase before the PRs.
