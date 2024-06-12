# entity-ci
CI for entity (org, event) creation, update, etc.

## Usage

```yaml
on:
  issues:
    types: [opened, reopened]

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  check-opened-issue-to-add-event:
    if: contains(github.event.issue.labels.*.name, 'add event')
    uses: swingapi/entity-ci/.github/workflows/create_pr_to_add_entity.yml@main
    with:
      type: event
      template_filename: 02-add_entity.yml
      reusable_workflow_repo: swingapi/entity-ci
    secrets:
      token: "${{ secrets.GH_TOKEN }}"

  check-opened-issue-to-update-event:
    if: contains(github.event.issue.labels.*.name, 'update event')
    uses: swingapi/entity-ci/.github/workflows/create_pr_to_update_entity.yml@main
    with:
      type: event
      template_filename: 03-update_entity.yml
      reusable_workflow_repo: swingapi/entity-ci
    secrets:
      token: "${{ secrets.GH_TOKEN }}"
```

## Workflow Permissions

In order to create a pull request, you must explicitly "**Allow GitHub Actions to create and approve pull requests**".

This setting can be found in a repo's settings under

> Code and automation > Actions > General > Workflow permissions

