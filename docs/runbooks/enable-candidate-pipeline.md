# Enable the candidate pipeline

The pipeline callers (`pipeline.yml`, `promote.yml`, `accept.yml`,
`candidate-sweep.yml`) are inert until the automation App, its environment
secret and the `update-candidate` ruleset exist. `ci.yml` and `verify-cache.yml`
need none of it. The mechanics are nix-fleet's: read
`docs/contracts/update-candidates.md` there rather than a copy here.

Order matters. The ruleset goes last, after one candidate has validated and
promoted by hand, because a required status that posts nothing blocks `main`.

## Create the App

The App needs these repository permissions:

| Permission      | Access | Used for                                        |
| --------------- | ------ | ----------------------------------------------- |
| Contents        | Write  | fast-forwarding `main`, managing candidate refs |
| Workflows       | Write  | updating files under `.github/workflows`        |
| Commit statuses | Write  | posting `update-candidate` / `update-accepted`  |
| Pull requests   | Write  | reading the source pull request                 |
| Metadata        | Read   | mandatory                                       |

Install it on `Shrub24/nix-dotfiles` only. Record the App ID and slug, and put
the private key in the `automation` environment as `AUTOMATION_APP_PRIVATE_KEY`;
the environment already restricts deployments to `main`.

```sh
gh variable set AUTOMATION_APP_ID --repo Shrub24/nix-dotfiles --body <app-id>
gh variable set AUTOMATION_APP_SLUG --repo Shrub24/nix-dotfiles --body <app-slug>
gh secret set AUTOMATION_APP_PRIVATE_KEY --repo Shrub24/nix-dotfiles \
  --env automation < <private-key-file>
```

`CANDIDATE_TARGETS=.#ciRoot`, `CANDIDATE_SYSTEMS=x86_64-linux`,
`CANDIDATE_RUNNER_SYSTEM=x86_64-linux`, `CANDIDATE_PROFILE=ci`,
`PROMOTION_POLICY=label` and `CACHE_PIN_NAME=auto` are already set.

## Prove one candidate by hand

Dispatch the pipeline against a pull request and require the whole chain to
report:

1. `ci` posts format, evaluate and consistency separately.
2. `update-candidate` appears on the pull request head, posted by the App.
3. Applying `accept-update` posts `update-accepted` on that same head.
4. A producer opening `automation/*` gets a prepared, built, verified candidate.
5. Promotion fast-forwards `main`; the dependent pin job creates
   `nix-dotfiles-main-x86_64-linux`, and `verify-cache` on `main` reports the
   pinned root served.

## Enable the ruleset

Only after that run. Require `update-candidate`, pinned to the App's integration
ID, with no bypass. Do not require `update-accepted`: revoking the acceptance
label deliberately posts it as a failure, so requiring it would block the
withdrawal path.

```sh
gh api --method POST repos/Shrub24/nix-dotfiles/rulesets --input - <<'JSON'
{
  "name": "candidate pipeline",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/main"], "exclude": [] } },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          { "context": "update-candidate", "integration_id": <app-id> }
        ]
      }
    }
  ]
}
JSON
```

## Known limits

Preparation merges `main` into a candidate, so `main` carries pipeline merge
commits. A fork pull request is not validated, and a candidate older than seven
days is refused at promotion. Both are nix-fleet's contract, not local choices.
