# GitHub Secrets Configuration Guide

This guide explains how to configure GitHub Secrets and Actions for the Golden Image CI/CD pipeline following ElevatedIQ patterns.

## Required Secrets

Create the following secrets in your GitHub repository at **Settings > Secrets and variables > Actions**:

### Infrastructure Secrets

```
GOLDEN_IMAGE_DB_PASSWORD          # Database password
GOLDEN_IMAGE_API_KEY              # API key for external services
GOLDEN_IMAGE_OAUTH_SECRET         # OAuth client secret
GOLDEN_IMAGE_SSH_PRIVATE_KEY      # SSH private key for deployment
GOLDEN_IMAGE_DEPLOY_KEY           # Deploy key for automation
```

### Cloud Provider Secrets

```
# For OpenStack deployment
OPENSTACK_USERNAME                # OpenStack username
OPENSTACK_PASSWORD                # OpenStack password
OPENSTACK_PROJECT_NAME            # OpenStack project name
OPENSTACK_AUTH_URL                # OpenStack auth URL
OPENSTACK_REGION_NAME             # OpenStack region

# For AWS (if applicable)
AWS_ACCESS_KEY_ID                 # AWS access key
AWS_SECRET_ACCESS_KEY             # AWS secret key

# For GCP (if applicable)
GCP_SERVICE_ACCOUNT_JSON          # GCP service account JSON
```

### Notification Secrets

```
SLACK_WEBHOOK_URL                 # Slack webhook for notifications
EMAIL_NOTIFICATION_ADDRESS        # Email for notifications
```

## Setting Up Secrets

### Via GitHub Web UI

1. Navigate to repository **Settings**
2. Go to **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Enter name and value
5. Click **Add secret**

### Via GitHub CLI

```bash
# Set individual secrets
gh secret set GOLDEN_IMAGE_DB_PASSWORD --body "your-password"
gh secret set GOLDEN_IMAGE_API_KEY --body "your-api-key"

# Set from file
gh secret set GOLDEN_IMAGE_SSH_PRIVATE_KEY < ~/.ssh/id_rsa
```

### Via Script

```bash
#!/bin/bash
# Set secrets from .env file

source .env.secrets

gh secret set GOLDEN_IMAGE_DB_PASSWORD --body "$DB_PASSWORD"
gh secret set GOLDEN_IMAGE_API_KEY --body "$API_KEY"
gh secret set GOLDEN_IMAGE_OAUTH_SECRET --body "$OAUTH_SECRET"
# ... add more secrets
```

## Environment Variables Configuration

### Development Environment

Create `.env.dev` (NOT committed):

```bash
GOLDEN_IMAGE_DB_PASSWORD=dev-password
GOLDEN_IMAGE_API_KEY=dev-api-key
TF_VAR_environment=dev
TF_VAR_enable_debug=true
```

### Staging Environment

Create `.env.staging` (used in CI/CD):

```bash
GOLDEN_IMAGE_DB_PASSWORD=${GOLDEN_IMAGE_DB_PASSWORD}
GOLDEN_IMAGE_API_KEY=${GOLDEN_IMAGE_API_KEY}
TF_VAR_environment=staging
TF_VAR_enable_debug=false
```

### Production Environment

Only through GitHub Environments:

```
Settings > Environments > Create environment "production"
Add required approvers
Set environment-specific secrets
```

## GitHub Environments Configuration

### Development Environment

1. Go to **Settings > Environments**
2. Click **New environment**
3. Name: `dev`
4. No protection rules needed

### Staging Environment

1. Name: `staging`
2. Add deployment branches: `develop`
3. No approvers required

### Production Environment

1. Name: `production`
2. Add deployment branches: `main`
3. **Set required approvers** (at least 2)
4. Link production secrets

## Secrets Used in Workflows

### CI/CD Validation Workflow

File: `.github/workflows/ci-validation.yml`

Secrets used:
- Environment variables injected automatically
- `GITHUB_TOKEN` (provided by GitHub)

### Deployment Workflow

File: `.github/workflows/deploy.yml`

Secrets used:
- `GOLDEN_IMAGE_DB_PASSWORD`
- `GOLDEN_IMAGE_API_KEY`
- `OPENSTACK_USERNAME`
- `OPENSTACK_PASSWORD`
- `OPENSTACK_AUTH_URL`

### Audit Workflow

File: `.github/workflows/audit.yml`

Secrets used:
- Optional: notification secrets

## Branch Protection Rules

### Main Branch Protection

1. Go to **Settings > Branches**
2. Click **Add rule**
3. Branch name pattern: `main`
4. Configure:
   - ✅ Require pull request reviews (2)
   - ✅ Require CODEOWNERS review
   - ✅ Require status checks to pass
   - ✅ Require deployment to be successful
   - ✅ Dismiss stale reviews
   - ✅ Require branches to be up to date

### Develop Branch Protection

1. Branch name pattern: `develop`
2. Configure:
   - ✅ Require pull request reviews (1)
   - ✅ Require status checks to pass
   - ⚠️ Allow self-review (for personal repos)

## Code Review Configuration

### CODEOWNERS File

Create `.github/CODEOWNERS`:

```
# Global owners
* @kushin77

# Infrastructure
infrastructure/ @kushin77
infrastructure/terraform/ @kushin77

# Image building
image-build/ @kushin77
image-build/packer/ @kushin77

# CI/CD
.github/workflows/ @kushin77

# Tests
tests/ @kushin77

# Security
scripts/security/ @kushin77
```

## Action Secrets Best Practices

### ✅ DO

- [ ] Rotate secrets regularly
- [ ] Use specific secret names for each service
- [ ] Audit secret usage in workflows
- [ ] Store in GitHub Secrets, never in code
- [ ] Document which secrets each workflow needs
- [ ] Use CODEOWNERS for sensitive areas
- [ ] Enable branch protection on main
- [ ] Require approvals for production

### ❌ DON'T

- [ ] Commit secrets to repository
- [ ] Use generic secret names (like "PASSWORD")
- [ ] Log secrets to workflow output
- [ ] Share secrets in pull requests
- [ ] Store credentials in .env files
- [ ] Use the same secret for multiple purposes
- [ ] Skip environment-specific secrets

## Validating Secrets

### Run Secret Validator

```bash
bash scripts/security/secret-validator.sh
```

This validates:
- No `.env` files committed
- No private keys in repository
- No AWS/GCP credentials in code
- No hardcoded secrets

### Pre-commit Hook

Install pre-commit hook to catch secrets:

```bash
# Install hook
cp scripts/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Run manually
.git/hooks/pre-commit
```

## Troubleshooting

### Secret Not Available in Workflow

**Problem**: Workflow can't access secret

**Solution**:
1. Verify secret name matches constant in workflow
2. Check event type triggers workflow
3. Ensure environment is configured
4. Review GitHub Actions logs

### Secret Accidentally Committed

**Action Plan**:
1. Rotate the secret immediately
2. Force push to remove from history (⚠️ use carefully)
3. Update GitHub Secrets
4. Run `git filter-branch` to clean history

### Workflow Permissions Issues

**Problem**: Workflow can't write to repository

**Solution**:
1. Go to **Settings > Actions > General**
2. Set **Workflow permissions** to `Read and write`
3. Or configure per-workflow in YAML:

```yaml
permissions:
  contents: write
  pull-requests: write
  security-events: write
```

## References

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [NIST-IA-5: Authenticator Management](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [ElevatedIQ Secrets Management](https://github.com/kushin77/ElevatedIQ-Mono-Repo)

## Next Steps

1. ✅ Configure secrets (see above)
2. ✅ Set up branch protection
3. ✅ Create CODEOWNERS
4. ✅ Test workflows on develop
5. ✅ Enable on main
6. ✅ Monitor audit logs
