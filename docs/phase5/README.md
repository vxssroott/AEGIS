# AEGIS Phase 5 — Self-Maintaining Core

Phase 5 introduces the self-maintenance substrate for AEGIS.

## Principles

AEGIS updates follow:

REQUEST
→ PRECHECK
→ BACKUP
→ STAGE
→ APPLY
→ HEALTH CHECK
→ COMMIT

If post-update health verification fails:

APPLY
→ FAILURE
→ RESTORE BACKUP
→ RECORD FAILURE

## Components

- Version management
- Release channels
- Repository integrity fingerprints
- SHA-256 file verification
- Health checks
- Diagnostic doctor
- Backup snapshots
- Recovery engine
- Update transaction boundary
- Diagnostic reports

## Safety

The update layer does not blindly execute remote code.

A future production updater must additionally require:

- authenticated release metadata
- trusted publisher/signature verification
- immutable artifact hashes
- staged installation
- process quiescence where required
- post-update verification
- automatic rollback
- audit events

The current implementation is the local transactional foundation for those capabilities.

## Commands planned

aegis version
aegis update
aegis update --check
aegis update --channel stable
aegis rollback
aegis doctor
aegis report
aegis fingerprint
