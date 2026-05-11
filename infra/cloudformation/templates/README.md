# CloudFormation (Project 2)

This directory is reserved for AWS CloudFormation templates and scripts used in:
- Project 2 (Fargate + DynamoDB + EFS)

## Naming Conventions
Stack names and resource names must follow the project convention:

tasktracker-dev-...

Do not use “chunk” in any AWS resource or stack names.

## Region
Primary working region: us-east-2 (Ohio)

## How we deploy
We use AWS CLI to deploy and delete stacks so everything is reproducible and easy to tear down.

### Deploy (example)
aws cloudformation deploy \
--region us-east-2 \
--stack-name tasktracker-dev-placeholder \
--template-file infra/cloudformation/templates/tasktracker-dev-placeholder.yml \
--no-fail-on-empty-changeset

### Delete (example)
aws cloudformation delete-stack \
--region us-east-2 \
--stack-name tasktracker-dev-placeholder

## Notes
- This placeholder stack intentionally creates no resources and costs nothing.
- Real templates will be added when Project 2 begins.
