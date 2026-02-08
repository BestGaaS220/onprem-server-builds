---
name: Infrastructure Change
about: Request changes to infrastructure, Terraform, or Ansible
title: "[INFRA] Brief description of the infrastructure change"
labels: ["infrastructure"]
---

## Description

Clear description of the infrastructure change.

## Type of Change

- [ ] New infrastructure component
- [ ] Modification to existing infrastructure
- [ ] Infrastructure optimization
- [ ] Cost reduction
- [ ] Performance improvement
- [ ] Security hardening

## Affected Components

- [ ] Terraform (IaC)
- [ ] Ansible (Configuration)
- [ ] Network (Security Groups, Routes, etc.)
- [ ] Storage (Volumes, Backups, etc.)
- [ ] Compute (Instances, Flavors, etc.)
- [ ] Other: (specify)

## Resource Sizing Impact

Impact on resources:

```
Before:
- CPU per instance: X cores
- RAM per instance: X GB
- Storage: X GB
- Instance count: X

After:
- CPU per instance: X cores
- RAM per instance: X GB
- Storage: X GB
- Instance count: X

Cost impact: ~X%
```

## Affected Environments

- [ ] Development
- [ ] Staging
- [ ] Production

## Testing Plan

How will these changes be tested?

1. Test case 1
2. Test case 2
3. Test case 3

## Rollback Plan

How to rollback if issues occur?

## Related Issues

Reference any related issues: #123, #456

## Implementation Steps

1. Step 1
2. Step 2
3. Step 3

## Success Criteria

- [ ] All tests passing
- [ ] Performance meets baseline
- [ ] No service disruption
- [ ] Monitoring configured
- [ ] Documentation updated

## Additional Context

Any other relevant information, diagrams, or references.
