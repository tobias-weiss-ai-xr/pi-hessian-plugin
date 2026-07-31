# Known Issues and Edge Cases

This document tracks known issues, edge cases, and potential bugs in pi, pi plugins, and related dependencies that may affect Hessian plugin users.

## Table of Contents

- [Pi Bash Tool Hanging Issues](#pi-bash-tool-hanging-issues)
- [Known Fixed Issues](#known-fixed-issues)
- [Recommendations for Users](#recommendations-for-users)
- [Debugging Tips](#debugging-tips)
- [References](#references)

---

## Pi Bash Tool Hanging Issues

### Issue: Potential Hanging with head/tail and Similar Commands

**Status**: 🔍 Under Investigation  
**Severity**: Medium  
**Affected Components**: `bash` tool, `waitForChildProcess` function  
**Last Updated**: 2025-01-15

#### Description

Pi's bash tool may occasionally hang when executing certain commands, particularly `head`, `tail`, and other commands that process piped data. This is related to the sophisticated child process waiting mechanism introduced to fix previous hanging issues with Hessian AI workflows.

#### Root Cause Analysis

##### 1. Issue #5303 Fix (Original Problem)
- **Location**: `@earendil-works/pi-coding-agent/dist/utils/child-process.js`
- **Purpose**: Fix hanging when "a short-lived child can exit while a detached descendant keeps its stdout/stderr pipe open"
- **Implementation**: Uses a rearming timer (100ms) that waits for pipes to fall idle
- **Impact on Hessian**: Hessian workflows that use bash commands for data processing may be affected

##### 2. Hessian-Specific Considerations

Hessian workflows often involve:
- Data preprocessing with bash commands
- Pipe operations for data transformation
- Background processes for data collection
- Long-running analytical commands

These patterns may interact with the child process waiting mechanism in unexpected ways.

##### 3. Related Fix #2389
- **Description**: "Fixed Windows bash execution hanging for commands that spawn detached descendants inheriting stdout/stderr handles"
- **Impact**: Similar to Hessian workflows that might spawn background processes
- **Location**: CHANGELOG.md

#### The Race Condition

The `waitForChildProcess` function has a potential race condition that affects Hessian workflows:

```
Scenario for 'cat data.json | head -n 100' (common Hessian preprocessing):
1. head command exits after reading 100 lines
2. onExit() fires, sets exited=true
3. onExit() calls maybeFinalizeAfterExit()
4. maybeFinalizeAfterExit() finds: stdoutEnded=false, stderrEnded=true
   - This happens because cat is still running in the background
5. onExit() calls armIdleTimer() (100ms)
6. Eventually cat receives SIGPIPE and exits
7. stdout 'end' event fires, sets stdoutEnded=true
8. onStdoutEnd() calls maybeFinalizeAfterExit()
9. Now both streams are ended → finalize immediately
```

**Problem**: The timer was armed unnecessarily, and in complex Hessian pipelines, this pattern can repeat multiple times.

#### Dual Listener Problem

Both `createLocalBashOperations.exec()` and `waitForChildProcess()` attach 'data' event listeners to the same `child.stdout` and `child.stderr` streams. For Hessian workflows processing large datasets, this means:

```javascript
// In bash.js (line ~78-79):
child.stdout?.on("data", handleData);  // Accumulates output for Hessian
child.stderr?.on("data", handleData);

// In child-process.js (line ~95-96):
child.stdout?.on("data", onData);      // Only arms timer if exited
child.stderr?.on("data", onData);
```

**Impact on Hessian**:
- ⚠️ Memory overhead from duplicate listeners (important for large datasets)
- ⚠️ Potential for listener cleanup issues in long-running workflows
- ⚠️ Unclear ownership of stream lifecycle in complex pipelines
- ⚠️ Possible race conditions between output accumulation and process waiting

#### Timer Loop Edge Case

For Hessian workflows with continuous data streams:

```javascript
// In child-process.js:
const onData = () => {
    if (exited && !settled) armIdleTimer();
};
```

**Potential issue for Hessian**: If a Hessian pipeline produces output after the main command exits (e.g., from background processes or buffered output), the timer keeps getting rearmed and never fires.

### Detected Edge Cases

#### 1. Exit Before Stream End
- **Severity**: Low (doesn't hang, but arms unnecessary timer)
- **Observation**: For very fast commands in Hessian preprocessing, exit event fires before stdout/stderr 'end' events
- **Impact**: Unnecessary timer arming, but streams still end quickly

#### 2. Pipelines with Background Processes
- **Severity**: Medium (specific to Hessian workflows)
- **Observation**: Hessian workflows that spawn background processes (e.g., `command &`) may keep streams open
- **Impact**: `waitForChildProcess` will wait for the background process to finish, which may not be intended

#### 3. Large Output Processing
- **Severity**: Medium (memory implications)
- **Observation**: Hessian workflows processing large datasets may hit memory limits with dual listeners
- **Impact**: Both listeners buffer data, potentially doubling memory usage

#### 4. Platform-Specific Detached Process Behavior
- **Severity**: Medium
- **Observation**: On Linux, processes are spawned with `detached: true`
- **Impact**: Hessian workflows on Linux vs Windows may behave differently

### Potential Hang Scenarios for Hessian

#### Scenario 1: Stream Never Ends
- **Trigger**: Hessian command that spawns a background data collector
- **Example**: `tail -f data.log &` in Hessian monitoring workflow
- **Cause**: Background process keeps stdout open
- **Result**: `maybeFinalizeAfterExit()` never succeeds, timer keeps resetting if data arrives

#### Scenario 2: Complex Pipeline with Multiple Processes
- **Trigger**: Hessian workflow with chained commands like `cat big.json | jq '.' | head -n 100`
- **Cause**: Intermediate processes may not clean up streams properly
- **Result**: Unexpected hanging or resource leaks

#### Scenario 3: Memory Pressure
- **Trigger**: Processing very large datasets in Hessian workflows
- **Cause**: Dual listeners double memory usage for buffering
- **Result**: Node.js may run out of memory, causing unpredictable behavior

---

## Known Fixed Issues

### ✅ Issue #2389: Windows Bash Execution Hanging
- **Description**: Commands that spawn detached descendants inheriting stdout/stderr handles would spin forever
- **Affected**: Hessian workflows on Windows with background processes
- **Status**: Fixed
- **Reference**: CHANGELOG.md

### ✅ Issue #5303: Output Truncation
- **Description**: Output was being truncated due to premature stream destruction
- **Impact**: Hessian workflows might lose data from long-running commands
- **Fix**: Introduced `waitForChildProcess` with rearming timer
- **Status**: Fixed
- **Reference**: Comment in `dist/utils/child-process.js`

### ✅ PR #4013: PowerShell Shell Command Output
- **Description**: Fixed PowerShell shell command output on Windows
- **Fix**: Only spawn detached processes on Unix platforms
- **Impact**: Hessian workflows on Windows now work more reliably
- **Status**: Fixed
- **Reference**: Comment in `dist/core/tools/bash.js` line 56

---

## Recommendations for Hessian Users

### If You Experience Hanging in Hessian Workflows

1. **Check Command Type**: Note which bash commands are hanging
2. **Simplify Pipeline**: Break complex Hessian pipelines into simpler steps
3. **Add Explicit Timeout**: Always include timeouts for long-running commands
4. **Avoid Background Processes**: Don't use `&` in Hessian bash commands
5. **Update Pi and Plugin**: Ensure you're using the latest versions

### Workarounds for Hessian Workflows

#### Add Explicit Timeout
Always include a timeout for bash commands in Hessian workflows:
```json
{
  "type": "bash", 
  "command": "cat data.json | jq 'select(.important)' | head -n 100",
  "timeout": 60
}
```

#### Avoid Background Processes
In Hessian workflows, don't spawn background processes:
```bash
# ❌ Don't do this in Hessian:
tail -f data.log &

# ✅ Do this instead:
tail -n 100 data.log
```

#### Use Temporary Files
For large datasets in Hessian workflows, use temporary files instead of pipes:
```bash
# Instead of processing in memory:
cat huge.json | jq '.' | head -n 100

# Use temporary files to avoid memory pressure:
jq '.' huge.json > temp.json && head -n 100 temp.json && rm temp.json
```

#### Break into Multiple Steps
Complex Hessian workflows should be broken into multiple tool calls:
```json
[
  {"type": "bash", "command": "jq '.' huge.json > temp.json", "timeout": 30},
  {"type": "bash", "command": "head -n 100 temp.json", "timeout": 10},
  {"type": "bash", "command": "rm temp.json"
]
```

#### Restart Pi Session
Sometimes a fresh session can resolve transient issues:
```bash
# Save current Hessian session context if needed
# Then start a new session
pi
```

---

## Debugging Tips for Hessian

### Enable Debug Logging for Hessian Workflows

Add debug logging to track Hessian workflow execution:

```javascript
// In your pi extension for Hessian:
const originalExec = pi.core.tools.bash.execute;
pi.core.tools.bash.execute = async function(...args) {
    const [toolCallId, params, signal, onUpdate, ctx] = args;
    console.log(`[HESSIAN-DEBUG] Bash command: ${params.command}`);
    console.log(`[HESSIAN-DEBUG] timeout: ${params.timeout || 'none'}`);
    
    const start = Date.now();
    try {
        const result = await originalExec.apply(this, args);
        const duration = Date.now() - start;
        console.log(`[HESSIAN-DEBUG] Completed in ${duration}ms`);
        return result;
    } catch (error) {
        const duration = Date.now() - start;
        console.log(`[HESSIAN-DEBUG] Failed after ${duration}ms: ${error.message}`);
        throw error;
    }
};
```

### Test Hessian Workflow Patterns

Test these diagnostic patterns for Hessian workflows:

```bash
# Test basic functionality
echo "test"

# Test with output (common in Hessian)
echo "{"key": "value"}" | jq '.'

# Test with pipes (very common in Hessian)
cat data.json | jq '.items | length'

# Test with head/tail (problematic for Hessian)
cat data.json | jq '.' | head -n 100
cat data.json | jq '.' | tail -n 100

# Test with redirection
jq '.' data.json > output.json

# Test with no output
jq 'select(.id == 42)' data.json

# Test with delayed output (common in API calls)
sleep 0.1 && echo "{"result": "ok"}"
```

### Monitor Memory Usage

For Hessian workflows processing large datasets:

```bash
# Check Node.js memory usage
node -e "console.log(process.memoryUsage())"

# Monitor memory during Hessian workflow
# In one terminal:
pi --interactive

# In another terminal:
watch -n 1 "ps aux | grep node | grep -v grep"
```

---

## Recommendations for Plugin Developers

### 1. Add Timeout Fallback for Hessian Commands

Modify `waitForChildProcess` to add an ultimate timeout for Hessian workflows:

```javascript
// In child-process.js or Hessian-specific wrapper:
const ULTIMATE_TIMEOUT_MS = 30000; // 30 seconds for Hessian

function waitForChildProcessWithTimeout(child, timeout = ULTIMATE_TIMEOUT_MS) {
    const ultimateTimeout = setTimeout(() => {
        if (!settled) {
            console.warn('[HESSIAN] Ultimate timeout reached, forcing cleanup');
            // Force cleanup
            child.stdout?.destroy();
            child.stderr?.destroy();
            finalize(exitCode);
        }
    }, timeout);

    // ... rest of original implementation

    const cleanup = () => {
        if (postExitTimer) clearTimeout(postExitTimer);
        if (ultimateTimeout) clearTimeout(ultimateTimeout);
        // ... rest of cleanup
    };
}
```

### 2. Optimize for Hessian Workflows

Create a Hessian-specific bash tool wrapper that:
- Uses single listener pattern for better memory efficiency
- Has higher default timeouts for data processing
- Provides better error messages for Hessian workflows
- Handles large datasets more efficiently

### 3. Add Hessian Workflow Validation

Validate Hessian bash commands before execution:

```javascript
function validateHessianBashCommand(command) {
    const warnings = [];
    
    // Check for background processes
    if (command.includes('&')) {
        warnings.push('Hessian workflows should not use background processes (&)');
    }
    
    // Check for potentially long-running commands without timeout
    if (!command.includes('timeout') && 
        (command.includes('tail -f') || 
         command.includes('watch') ||
         command.includes('sleep'))) {
        warnings.push('Consider adding timeout for long-running commands');
    }
    
    // Check for memory-intensive operations
    if (command.includes('cat') && 
        command.includes('|') && 
        !command.includes('head') && 
        !command.includes('tail')) {
        warnings.push('Consider using temporary files for large dataset processing');
    }
    
    return warnings;
}
```

---

## References

### Source Code Locations

- `dist/utils/child-process.js`: `waitForChildProcess` function
- `dist/core/tools/bash.js`: Bash tool implementation
- `CHANGELOG.md`: Issue #2389 fix

### Key Files

- **Pi Repository**: https://github.com/earendil-works/pi
- **Main Issue Tracker**: https://github.com/earendil-works/pi/issues
- **Issue #5303**: Mentioned in code comments (earendil-works/pi#5303)
- **PR #2389**: https://github.com/badlogic/pi-mono/pull/2389
- **PR #4013**: https://github.com/badlogic/pi-mono/pull/4013

### Hessian-Specific References

- **Hessian AI**: https://hessian.ai
- **Pi Documentation**: https://pi.dev
- **Pi Discord**: https://discord.com/invite/3cU7Bz4UPx

---

## Hessian-Specific Issue Tracking

| Date | Issue | affect on Hessian | Status |
|------|-------|-------------------|--------|
| 2025-01-15 | Bash tool hanging with head/tail | Medium | Under Investigation |
| 2025-01-15 | Dual listener memory overhead | High for large datasets | Under Investigation |
| 2025-01-15 | Background process handling | Medium | Under Investigation |

---

## Change History

| Date | Change | Author |
|------|--------|--------|
| 2025-01-15 | Initial analysis of bash tool hanging issues for Hessian | Pi Coding Agent |
| 2025-01-15 | Added Hessian-specific considerations and workarounds | Pi Coding Assistant |
| 2025-01-15 | Documented race conditions and edge cases for Hessian workflows | Pi Coding Assistant |
