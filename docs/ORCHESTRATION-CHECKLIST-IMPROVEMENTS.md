# Orchestration Prompt Checklist Improvements

## Date
November 10, 2025

## Problem Identified

**User feedback:** "The orchestration-prompt.md is missing checklists on each phase, so that AI may feel confused when we run Phase 2."

### Root Cause

The original orchestration prompt had:
- ✅ General descriptions of what to do
- ✅ Steps listed as numbered items
- ❌ No explicit checklists for each phase
- ❌ No clear structure to follow
- ❌ Missing "Getting Started" guidance
- ❌ No final completion verification

**Result**: Claude in Phase 2 might not know exactly what steps to take or how to track progress systematically.

## Solution Implemented

### Enhanced Orchestration Prompt Structure

The orchestration-prompt.md now includes:

#### 1. Getting Started Section (NEW)

**Clarifies Claude's role:**
```markdown
## Getting Started

**Your role:** You are the orchestrator. You coordinate agents and synthesize results.

**What you DO:**
- ✅ Create TodoWrite tasks to track progress
- ✅ Tell each agent to execute their research assignment
- ✅ Read agent findings files after they complete
- ✅ Synthesize all findings into final-analysis.md

**What you DON'T do:**
- ❌ You don't execute research yourself
- ❌ You don't write agent findings files
- ❌ You don't need to create agents (already defined in agents.json)

**How agents work:**
- Each agent has a custom system prompt with their assignment
- Agents execute autonomously when you tell them to start
- Agents have access to all tools (WebSearch, Read, Write, etc.)
- Agents save their own findings files
```

**Benefits:**
- Prevents confusion about Claude's role
- Clarifies what orchestration means
- Sets expectations for agent behavior

#### 2. Phase-by-Phase Checklists (ENHANCED)

**Phase 1: Setup and Task Assignment**
```markdown
**Checklist:**
- [ ] Read and understand the research plan
- [ ] Review all agent definitions in agents.json
- [ ] Use TodoWrite to create a task for EACH agent listed below
- [ ] Verify all agents have clear, non-overlapping assignments

**Example TodoWrite tasks:**
```
- [ ] ra-1-[role]: [Brief description]
- [ ] ra-2-[role]: [Brief description]
- [ ] ra-N-[role]: [Brief description]
- [ ] ra-v-verification: Cross-verify all findings (if deep mode)
- [ ] Synthesize final analysis
```
```

**Phase 2: Agent Research Execution**
```markdown
**For EACH agent (ra-1, ra-2, ra-3, ...):**

**Checklist:**
- [ ] Mark the agent's TodoWrite task as in_progress
- [ ] Tell the specific agent to start their research
- [ ] Agent executes their assignment autonomously:
  - Runs WebSearch for their specific topic
  - Analyzes findings with citations
  - Marks confidence levels (🟢🟡🔴)
  - Saves to their designated findings file
- [ ] Verify the agent's findings file was created
- [ ] Mark the agent's TodoWrite task as completed
- [ ] Move to next agent

**Important:**
- Agents can work in parallel if you prefer
- Each agent saves their OWN findings - you don't write for them
- Wait until ALL agent findings files exist before proceeding
```

**Phase 3: Verification (if required)**
```markdown
**Checklist:**
- [ ] Confirm all agent findings files exist in ./assistants/
- [ ] Mark ra-v-verification task as in_progress
- [ ] Tell verification agent to:
  - Read ALL agent findings files
  - Cross-check statistical claims
  - Identify contradictions between sources
  - Flag single-source claims needing verification
  - Check for bias or missing perspectives
- [ ] Verify ra-v-verification-findings.md was created
- [ ] Mark ra-v-verification task as completed
```

**Phase 4: Synthesis and Final Analysis**
```markdown
**Checklist:**
- [ ] Mark synthesis task as in_progress
- [ ] Read ALL findings files from ./assistants/ directory
- [ ] Create comprehensive final-analysis.md with:
  - [ ] Executive Summary (2-3 paragraphs)
  - [ ] Research Methodology section
  - [ ] Detailed Findings (organized by themes)
  - [ ] Cross-Cutting Insights
  - [ ] Limitations & Gaps
  - [ ] Areas of Uncertainty
  - [ ] Recommendations (if applicable)
  - [ ] Complete Bibliography (all sources, deduplicated)
- [ ] Save to: ./final-analysis.md
- [ ] Mark synthesis task as completed
- [ ] Confirm research is complete
```

#### 3. Important Guidelines (NEW)

**Progress Tracking**
```markdown
- **ALWAYS use TodoWrite** at the start to create tasks for all agents
- Mark tasks as **in_progress** when starting
- Mark tasks as **completed** immediately after finishing
- This helps you and the user track progress
```

**Agent Communication**
```markdown
- Tell the agent explicitly: "Please execute your research assignment"
- Reference the agent by name: "ra-1-core-technology, please start your research"
- Agents know their assignment from their system prompt
- You don't need to repeat their full assignment to them
```

**File Management**
```markdown
- Agents save their findings to ./assistants/ra-*-findings.md
- Verify files exist before moving to synthesis
- Read all findings files using the Read tool
- Your synthesis goes to ./final-analysis.md
```

**Quality Assurance**
```markdown
- Each agent has quality standards embedded in their prompt
- Agents will include citations, confidence markers, and sources
- Your synthesis should preserve this quality metadata
- Note any gaps or conflicts in your final analysis
```

#### 4. Final Completion Checklist (NEW)

```markdown
## Final Completion Checklist

Before finishing, verify:
- [ ] All agent findings files exist in ./assistants/
- [ ] Verification report exists (if deep mode)
- [ ] final-analysis.md exists and is comprehensive
- [ ] All TodoWrite tasks are marked completed
- [ ] User can see clear completion message
```

#### 5. Ready to Begin Section (NEW)

```markdown
## Ready to Begin?

Start with Phase 1: Setup and Task Assignment.
Create TodoWrite tasks for all agents, then proceed through each phase systematically.

Begin orchestration now!
```

## Comparison: Before vs After

### Before (Confusing)

```markdown
## Your Orchestration Tasks

### 1. Agent Task Assignment
Use TodoWrite to create a task for each agent:
- [ ] ra-1-[role]: [Brief task description]
- [ ] ra-2-[role]: [Brief task description]

### 2. Execute Research Phase
For each agent in sequence or parallel:
1. Mark agent's task as in_progress
2. Tell the agent to execute their research
3. Wait for agent to save their findings file
4. Mark agent's task as completed
5. Move to next agent
```

**Problems:**
- No clear structure for what to do first
- Missing explicit checklists
- Unclear about roles and responsibilities
- No guidance on completion verification

### After (Clear and Structured)

```markdown
## Getting Started

**Your role:** You are the orchestrator...
**What you DO:** ✅ ...
**What you DON'T do:** ❌ ...

## Your Orchestration Workflow

Follow these phases in order. Use TodoWrite to track progress.

### Phase 1: Setup and Task Assignment

**Checklist:**
- [ ] Read and understand the research plan
- [ ] Review all agent definitions in agents.json
- [ ] Use TodoWrite to create a task for EACH agent
- [ ] Verify all agents have clear assignments

### Phase 2: Agent Research Execution

**For EACH agent:**

**Checklist:**
- [ ] Mark task as in_progress
- [ ] Tell agent to start
- [ ] Agent executes autonomously
- [ ] Verify findings file created
- [ ] Mark task as completed
...

## Final Completion Checklist

Before finishing, verify:
- [ ] All agent findings exist
- [ ] final-analysis.md created
- [ ] All tasks completed
```

**Improvements:**
- ✅ Clear phase-by-phase structure
- ✅ Explicit checklists for each phase
- ✅ "Getting Started" section clarifies role
- ✅ Important Guidelines section
- ✅ Final completion verification
- ✅ "Ready to Begin?" call to action

## Expected Impact

### Before (Problems)
- ❌ Claude might not know where to start
- ❌ Might skip TodoWrite task creation
- ❌ Unclear about agent coordination
- ❌ Might try to write agent findings itself
- ❌ No systematic verification of completion

### After (Benefits)
- ✅ Clear starting point (Phase 1)
- ✅ Explicit instruction to use TodoWrite
- ✅ Clear agent communication guidelines
- ✅ Understands orchestration role vs execution
- ✅ Systematic completion verification

## Code Location

**File**: `ccheavy.sh`
**Section**: `create_phase1_prompt()` function
**Lines**: 258-435 (orchestration-prompt.md template)

**Changes**:
- **Added**: Getting Started section (~15 lines)
- **Enhanced**: Phase checklists with explicit items (~40 lines)
- **Added**: Important Guidelines section (~25 lines)
- **Added**: Final Completion Checklist (~7 lines)
- **Added**: Ready to Begin section (~4 lines)
- **Total**: ~90 lines of additional structure and guidance

## Testing Validation

### Syntax Check
```bash
bash -n ccheavy.sh
# ✅ No syntax errors
```

### What to Test

**Phase 1 Output:**
- Verify orchestration-prompt.md is generated
- Check it includes all new sections:
  - Getting Started
  - Phase 1-4 checklists
  - Important Guidelines
  - Final Completion Checklist

**Phase 2 Behavior:**
- Claude should create TodoWrite tasks at start
- Should systematically work through phases
- Should mark tasks as in_progress/completed
- Should verify files exist before proceeding
- Should create final-analysis.md at end

## Example Orchestration Flow

### What Claude Will Do in Phase 2

**Step 1: Read orchestration-prompt.md**
```
I see I need to:
1. Create TodoWrite tasks for all agents
2. Execute each agent systematically
3. Verify their output
4. Synthesize results
```

**Step 2: Create TodoWrite tasks**
```
- [ ] ra-1-core-tech: Research technical fundamentals
- [ ] ra-2-use-cases: Research applications
- [ ] ra-3-ecosystem: Research tooling
- [ ] Synthesize final analysis
```

**Step 3: Execute agents one by one**
```
Marking ra-1-core-tech as in_progress...
ra-1-core-tech, please execute your research assignment.
[Agent executes]
Verifying ./assistants/ra-1-core-tech-findings.md exists... ✓
Marking ra-1-core-tech as completed ✓

Marking ra-2-use-cases as in_progress...
```

**Step 4: Synthesize**
```
Reading all findings files...
Creating final-analysis.md...
Marking synthesis as completed ✓

Final verification:
✓ All agent findings exist
✓ final-analysis.md created
✓ All tasks completed

Research complete!
```

## Benefits Summary

### For Claude (Phase 2 Execution)
1. **Clear structure**: Knows exactly what to do and in what order
2. **Systematic approach**: Checklists prevent skipping steps
3. **Role clarity**: Understands orchestration vs execution
4. **Progress tracking**: TodoWrite provides visibility
5. **Quality assurance**: Final checklist ensures completeness

### For Users
1. **Predictable behavior**: Claude follows consistent workflow
2. **Progress visibility**: TodoWrite shows what's happening
3. **Complete output**: Final checklist ensures nothing missed
4. **Quality results**: Systematic approach improves research

### For Debugging
1. **Clear phases**: Easy to identify where issues occur
2. **Checkpoints**: TodoWrite shows progress
3. **Validation**: Explicit file existence checks
4. **Reproducible**: Same workflow every time

## Future Enhancements (Optional)

1. **Time estimates**: Add expected duration for each phase
2. **Error handling**: Checklist items for handling agent failures
3. **Parallel execution**: More guidance on when/how to parallelize
4. **Incremental saving**: Guidance on saving intermediate results
5. **Recovery**: Instructions for resuming interrupted research

## Conclusion

The enhanced orchestration prompt transforms Phase 2 execution from:
- **Before**: General guidance that might confuse Claude
- **After**: Systematic, checklist-driven workflow that ensures completeness

**Key Improvements**:
- ✅ Clear phase structure (4 phases with checklists)
- ✅ Getting Started section (role clarity)
- ✅ Important Guidelines (best practices)
- ✅ Final Completion Checklist (verification)
- ✅ Systematic TodoWrite tracking

**Status**: ✅ Implemented and syntax validated

**Impact**: High - Transforms Phase 2 from potentially confusing to systematically clear

**Version**: 2.3 (Orchestration Checklist Improvements)

**Date**: November 10, 2025
