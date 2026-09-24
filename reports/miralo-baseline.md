# Miralo — Real Verification Baseline Report

**Execution Timestamp:** 2026-09-21T16:51:00+05:30  
**Environment:** Fedora Linux 44 (x86_64), Flutter 3.47.1, Dart 3.13.1  
**Repository Path:** `/home/aarush/Myoffice/Personal Projects/miralo`

---

## 1. Git Status
```
?? android/build/
```
Working tree has untracked build artifacts in `android/build/` (which should be in `.gitignore`). No uncommitted code changes prior to audit.

---

## 2. Flutter Static Analysis
```bash
$ flutter analyze
Analyzing miralo...
No issues found! (ran in 4.5s)
```
- **Issues Found:** 0 errors, 0 warnings, 0 lints.

---

## 3. Test Suite Baseline
```bash
$ flutter test
00:02 +12: All tests passed!
```
- **Total Tests:** 12
- **Passed:** 12
- **Failed:** 0
- **Observations during execution:**
  - `[core/no-app] No Firebase App '[DEFAULT]' has been created` notices logged when AuthProvider and PrivateChatProvider tests interact with un-mocked or fallback Firebase instances.
  - Test `AuthProvider Tests Special users bypass key check correctly` verifies a backdoor/bypass where specific users bypass license/key checks.

---

## 4. Test Coverage
- Executed: `flutter test --coverage`
- Output: `coverage/lcov.info` generated successfully.

---

## 5. Flutter Doctor Summary
- **Flutter Version:** 3.47.1 (channel stable)
- **Dart Version:** 3.13.1
- **Android SDK:** 36.0.0
- **Connected Devices:**
  - SM A366B (mobile) • Android 16 (API 36)
  - sdk gphone16k x86 64 (emulator) • Android 17 (API 37)
  - Linux (desktop) • linux-x64
  - Chrome (web) • web-javascript
- **Issues Flagged:**
  - Android license status unaccepted (non-blocking for testing/Linux desktop).
  - Intermittent network latency check to storage.googleapis.com.
