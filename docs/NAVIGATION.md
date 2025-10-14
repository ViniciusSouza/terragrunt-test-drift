# 🗺️ Documentation Navigation Guide

## Quick Start - Choose Your Path

```
                    🚨 DRIFT DETECTED! 🚨
                            |
                            v
        ┌───────────────────────────────────────┐
        │   What do you need?                   │
        └───────────────────────────────────────┘
                            |
            ┌───────────────┴───────────────┐
            |                               |
            v                               v
    ┌──────────────┐              ┌──────────────────┐
    │ QUICK FIX    │              │ DETAILED ANALYSIS│
    │ (Urgent)     │              │ (Full Review)    │
    └──────────────┘              └──────────────────┘
            |                               |
            v                               v
    📄 drift-quick-fix.md         📄 DRIFT_REMEDIATION.md
    • One-liner commands          • Complete analysis
    • Fast remediation            • Risk assessment
    • Verification steps          • All options
                                  • Prevention guide
            |                               |
            └───────────────┬───────────────┘
                            |
                            v
                  ┌─────────────────┐
                  │ NEED TO RESPOND? │
                  └─────────────────┘
                            |
                            v
                📄 ISSUE_RESPONSE.md
                • Stakeholder summary
                • Security highlights
                • Quick remediation
                • Validation steps
```

## 📚 Documentation Tree

```
📁 terragrunt-test-drift/
│
├── 📄 README.md                          ← Start here (Repository overview)
│   └── Links to: drift remediation docs
│
├── 📄 DRIFT_REMEDIATION.md              ← Main guide (Comprehensive)
│   ├── Drift analysis per resource
│   ├── Security risk assessment
│   ├── Remediation options (2)
│   ├── Root cause analysis
│   └── Prevention measures
│
├── 📄 SOLUTION_SUMMARY.md               ← Solution overview
│   ├── What was created
│   ├── How to use
│   └── Quality assurance
│
├── 📁 docs/                             ← Documentation hub
│   │
│   ├── 📄 README.md                     ← Documentation index
│   │   ├── File directory
│   │   ├── Use case guide
│   │   └── Quick reference
│   │
│   ├── 📄 ISSUE_RESPONSE.md             ← Issue template
│   │   ├── Executive summary
│   │   ├── Quick remediation
│   │   └── Validation
│   │
│   ├── �� drift-quick-fix.md            ← Quick reference
│   │   ├── Fast commands
│   │   ├── One-liners
│   │   └── Expected values
│   │
│   └── 📄 NAVIGATION.md                 ← This file
│
└── 📁 scripts/
    ├── 🔧 create-drift.ps1              ← Create test drift
    └── 🔧 fix-drift.sh                  ← Fix drift (automated)
```

## 🎯 Choose Your Document

### I need to...

#### 🔥 Fix drift IMMEDIATELY
→ **[Quick Fix Reference](./drift-quick-fix.md)**
```bash
# One command to rule them all
make fix-drift
```

#### 📊 Understand the drift in DETAIL
→ **[Drift Remediation Guide](../DRIFT_REMEDIATION.md)**
- Complete analysis
- Risk assessment
- All remediation options

#### 💬 RESPOND to an issue/alert
→ **[Issue Response Template](./ISSUE_RESPONSE.md)**
- Executive summary
- Security assessment
- Quick action items

#### 🗺️ FIND documentation
→ **[Documentation Index](./README.md)**
- File directory
- Use case guide
- Quick reference table

#### 🎓 LEARN about the solution
→ **[Solution Summary](../SOLUTION_SUMMARY.md)**
- What was created
- How to use everything
- Quality metrics

#### 🚀 GET STARTED with the repo
→ **[Main README](../README.md)**
- Repository overview
- Prerequisites
- Quick start guide

## 🔄 Workflow Paths

### Testing Workflow (Development)
```
1. 📖 README.md
2. 🔧 make add-drift
3. 🔍 make plan
4. 📚 Quick Fix Reference (if needed)
5. 🔧 make fix-drift
```

### Production Incident Response
```
1. 🚨 Alert received
2. 📄 ISSUE_RESPONSE.md (immediate context)
3. 📊 DRIFT_REMEDIATION.md (full analysis)
4. 🛠️ Choose remediation path
5. ✅ Execute and validate
6. 📝 Document incident
```

### Learning/Exploration
```
1. 📖 README.md
2. 🗺️ NAVIGATION.md (this file)
3. 📚 Documentation Index
4. 📊 Pick relevant guide
```

## 📖 Document Relationships

```
                    README.md
                        |
        ┌───────────────┼───────────────┐
        |               |               |
        v               v               v
DRIFT_REMEDIATION  docs/README  SOLUTION_SUMMARY
        |               |
        |       ┌───────┼───────┐
        |       |       |       |
        |       v       v       v
        └──> ISSUE   drift   NAVIGATION
           RESPONSE quick-fix    (this)
```

## 🎨 Color-Coded Priority

- 🔴 **Critical/Urgent**: Use Quick Fix Reference
- 🟡 **Important**: Read Drift Remediation Guide
- 🟢 **Informational**: Browse Documentation Index
- 🔵 **Learning**: Start with README and Solution Summary

## 🔍 Search by Keywords

| Keyword | Best Document |
|---------|---------------|
| Quick fix, emergency, urgent | [drift-quick-fix.md](./drift-quick-fix.md) |
| Analysis, detailed, comprehensive | [DRIFT_REMEDIATION.md](../DRIFT_REMEDIATION.md) |
| Security, TLS, vulnerability | [DRIFT_REMEDIATION.md](../DRIFT_REMEDIATION.md) |
| Issue response, alert, stakeholder | [ISSUE_RESPONSE.md](./ISSUE_RESPONSE.md) |
| Prevention, best practices, production | [DRIFT_REMEDIATION.md](../DRIFT_REMEDIATION.md) |
| Getting started, overview | [README.md](../README.md) |
| All docs, index, map | [docs/README.md](./README.md) |
| Automation, script | `scripts/fix-drift.sh` |
| Create drift, testing | `scripts/create-drift.ps1` |

## ⚡ One-Command Solutions

```bash
# View all documentation
ls -la docs/ DRIFT_REMEDIATION.md README.md

# Read specific guide
cat docs/drift-quick-fix.md          # Quick fix
cat DRIFT_REMEDIATION.md             # Full guide
cat docs/ISSUE_RESPONSE.md           # Issue template

# Use automation
make fix-drift                        # Fix drift
make add-drift                        # Create drift
make plan                             # Detect drift
```

---

**💡 Tip**: Bookmark this file for quick navigation!
