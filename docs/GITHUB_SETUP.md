# GitHub Repository Configuration Guide

This guide provides step-by-step instructions for configuring the GitHub repository with branch protection, secrets management, and automation best practices.

## Prerequisites
- Repository owner access
- GitHub CLI installed (optional but recommended)
- Access to OpenStack credentials

## 1. Branch Protection Configuration

### Main Branch Protection
Follow these steps to configure protection on the `main` branch:

1. Navigate to repository → Settings → Branches
2. Click "Add rule" under "Branch protection rules"
3. Configure for branch name pattern: `main`
4. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Include administrators
   - ✅ Require branches to be up to date before merging
   - ✅ Require linear history
   - ✅ Restrict who can push to matching branches (optional - select maintainers only)
5. Disable:
   - ❌ Allow force pushes
   - ❌ Allow deletions
6. Save changes

### Develop Branch Protection
1. Click "Add rule" for develop branch
2. Configure for branch name pattern: `develop`
3. Enable:
   - ✅ Require a pull request before merging (minimum 1 reviewer)
   - ✅ Require status checks to pass before merging
   - ✅ Require CODEOWNERS review
   - ✅ Dismiss stale pull request approvals
   - ✅ Require branches to be up to date before merging
4. Disable:
   - ❌ Allow force pushes
   - ❌ Allow deletions
5. Save changes

## 2. Secrets Configuration

### Required Secrets for CI/CD Pipelines

Navigate to Settings → Secrets and variables → Actions and create these secrets:

#### OpenStack Credentials
```
OPENSTACK_AUTH_URL          - https://your-openstack.example.com:5000/v3
OPENSTACK_USERNAME          - Your OpenStack username
OPENSTACK_PASSWORD          - Your OpenStack password
OPENSTACK_PROJECT           - Your OpenStack project name
OPENSTACK_USER_DOMAIN_NAME  - Domain name (usually 'Default')
OPENSTACK_PROJECT_DOMAIN    - Project domain (usually 'Default')
```

#### Terraform Backend (if applicable)
```
TF_BACKEND_BUCKET           - S3/Swift bucket name for state
TF_BACKEND_KEY              - State file key/path
TF_BACKEND_REGION           - Region for backend
TF_BACKEND_ACCESS_KEY       - Access key for backend
TF_BACKEND_SECRET_KEY       - Secret key for backend
```

#### Artifact Registry
```
REGISTRY_URL                - Container registry URL (if used)
REGISTRY_USERNAME           - Registry username
REGISTRY_PASSWORD           - Registry password or token
REGISTRY_TOKEN              - Alternative to username/password
```

#### Notification/Monitoring
```
SLACK_WEBHOOK_URL           - For Slack notifications (optional)
SLACK_CHANNEL               - Slack channel for alerts
```

**Setting Secrets via CLI:**
```bash
# Using GitHub CLI
gh secret set OPENSTACK_AUTH_URL --body "https://openstack.example.com:5000/v3"
gh secret set OPENSTACK_USERNAME --body "your-username"
gh secret set OPENSTACK_PASSWORD --body "your-password"
# ... repeat for other secrets
```

## 3. Repository Settings

### General Settings
1. Go to Settings → General
2. Configure:
   - Default branch: `develop` (for active development)
   - Allow squash merging: ✅ (for clean history)
   - Allow rebase merging: ✅ (for linear history)
   - Allow auto-merge: ❌ (require manual review)
   - Always suggest updating PR branches: ✅
   - Delete head branches: ✅ (auto-cleanup)

### Actions Settings
1. Go to Settings → Actions → General
2. Configure:
   - Actions permissions: Allow all actions and reusable workflows
   - Workflow permissions: Read repository contents and packages
   - Default permissions: Read-only (restrictive)

### Code Security Settings
1. Go to Settings → Code security and analysis
2. Enable:
   - ✅ Dependabot alerts
   - ✅ Dependabot security updates
   - ✅ Secret scanning (if available in your plan)

## 4. Webhooks Configuration (Optional)

For integration with external systems:

1. Navigate to Settings → Webhooks
2. Click "Add webhook"
3. Configure:
   - Payload URL: Your CI/CD system endpoint
   - Content type: application/json
   - Events: Select "Let me select individual events"
     - ✅ Push
     - ✅ Pull request
     - ✅ Workflow run
4. Active: ✅
5. Click "Add webhook"

## 5. Deploy Keys (for CI/CD)

If using deploy keys for access:

1. Go to Settings → Deploy keys
2. Click "Add deploy key"
3. Configure:
   - Title: `CI/CD Deploy Key - {environment}`
   - Key: Paste your public SSH key
   - Allow write access: ✅ (if needed for deployments)
4. Add key

## 6. Team and Collaborator Management

### Add Team Members
1. Go to Settings → Collaborators and teams
2. Click "Add teams" or "Add people"
3. Assign appropriate roles:
   - `maintain` - for release managers
   - `triage` - for issue management
   - `write` - for developers
   - `read` - for observers

### Configure CODEOWNERS
1. Create `.github/CODEOWNERS` file (already created)
2. Define code ownership:
```
# Infrastructure
infrastructure/terraform/    @team:infrastructure-team
infrastructure/ansible/      @team:infrastructure-team
image-build/packer/          @team:infrastructure-team

# Documentation
docs/                        @team:documentation-team
*.md                         @team:documentation-team

# CI/CD
.github/workflows/           @team:devops-team
Makefile                     @team:devops-team
```

## 7. Verification Checklist

After completing all above configurations, verify:

- [ ] Main branch has protection enabled
- [ ] Develop branch has protection enabled  
- [ ] All required secrets are configured
- [ ] GitHub Actions have permission to read repository
- [ ] Workflows can access secrets (test with a dry-run)
- [ ] CODEOWNERS is properly configured
- [ ] No direct pushes can bypass protection
- [ ] Notification channels are configured
- [ ] Deploy keys are in place (if needed)
- [ ] Team members have appropriate access levels

## 8. Testing Branch Protection

To verify branch protection is working:

1. Try to push directly to `main` (should fail):
```bash
git checkout main
echo "test" > test.txt
git add test.txt
git commit -m "test"
git push origin main  # This should fail
```

2. Verify PR workflow:
   - Create a feature branch
   - Make a commit
   - Push to GitHub
   - Create a PR
   - Verify status checks run
   - Verify approval is required
   - Merge after approval

## 9. Automated Configuration (Optional)

You can automate some of these settings using:

- **GitHub CLI**: See examples in "Setting Secrets via CLI" above
- **Terraform Provider**: Use `terraform-provider-github` for IaC
- **GitHub Actions**: Create workflow to configure settings on repository creation

### Example: Setting secrets with GitHub CLI
```bash
#!/bin/bash
# Set all required secrets

SECRETS=(
  "OPENSTACK_AUTH_URL:https://openstack.example.com:5000/v3"
  "OPENSTACK_USERNAME:your-username"
  "OPENSTACK_PASSWORD:your-password"
  "OPENSTACK_PROJECT:your-project"
)

for secret in "${SECRETS[@]}"; do
  key="${secret%:*}"
  value="${secret#*:}"
  gh secret set "$key" --body "$value"
done

echo "All secrets configured!"
```

## 10. Troubleshooting

### Workflows not triggering
- [ ] Check Actions tab for errors
- [ ] Verify secrets are configured
- [ ] Check branch protection allows status checks
- [ ] Review workflow event triggers

### PR approvals not enforcing
- [ ] Verify "Require pull request before merging" is enabled
- [ ] Check CODEOWNERS path patterns match files
- [ ] Verify team members have write access

### Secrets not accessible in workflows
- [ ] Verify secret exists in Actions Secrets (not regular Secrets)
- [ ] Check workflow permissions in Settings → Actions
- [ ] Ensure workflow has `secrets: inherit` if using reusable workflows

## References
- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
