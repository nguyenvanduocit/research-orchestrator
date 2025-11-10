# Orchestration Fix - Agent Task Assignment

## Problem Identified

The user reported that agents.json was being generated correctly, but Claude in Phase 2 didn't know which agent should work on which task. This caused agents to not execute their assigned research properly.

### Root Cause

Phase 1 was generating:
- ✅ `research-plan.md` - User-friendly plan (for approval)
- ✅ `agents.json` - Agent definitions with system prompts

But when Phase 2 launched with `claude --agents $(cat agents.json)`, Claude received:
- The agent definitions (who they are, what expertise they have)
- BUT NO instructions on:
  - What the overall research task is
  - Which agent should work on which part
  - How to coordinate between agents
  - What the expected workflow is
  - What the final deliverables should be

**Result**: Claude had the agents but no orchestration instructions, so agents didn't execute their tasks properly.

## Solution Implemented

### Phase 1 Enhancement

Updated `create_phase1_prompt()` to instruct Opus to generate **three files** instead of two:

1. **research-plan.md** - User-friendly plan (unchanged)
2. **agents.json** - Agent definitions (unchanged)
3. **orchestration-prompt.md** - NEW: Orchestration instructions for Phase 2

### orchestration-prompt.md Content

This new file tells Claude in Phase 2:

#### 1. Research Context
- What the overall research question is
- What the research configuration is (depth, word count, focus areas)

#### 2. Available Agents
- Lists all agents with their roles
- Explains what each agent researches

#### 3. Orchestration Workflow
Clear step-by-step instructions:

**Step 1: Agent Task Assignment**
- Use TodoWrite to create a task for each agent
- Track progress through the research

**Step 2: Execute Research Phase**
- For each agent:
  1. Mark task as in_progress
  2. Tell the agent to execute their research
  3. Wait for agent to save findings file
  4. Mark task as completed
  5. Move to next agent

**Step 3: Verification Phase (if deep mode)**
- Tell verification agent to read all findings
- Cross-check claims and identify conflicts
- Save verification report

**Step 4: Synthesis Phase**
- Read all findings files
- Synthesize into comprehensive analysis
- Create final-analysis.md

#### 4. Expected Outputs
Lists all files that should exist after completion:
- research-plan.md (already exists)
- agents.json (already exists)
- assistants/ra-1-*.md
- assistants/ra-2-*.md
- ...
- assistants/ra-v-verification.md (if deep mode)
- final-analysis.md (Claude creates this)

#### 5. Important Notes
- Use TodoWrite for progress tracking
- Each agent saves their own findings
- Claude orchestrates and synthesizes
- Quality standards are embedded in agent prompts

## Code Changes

### Phase 1 Prompt (ccheavy.sh:258-340)

**Added**: Task 3 section instructing Opus to create orchestration-prompt.md

```bash
### Task 3: Create Orchestration Prompt

Save to: `./orchestration-prompt.md`

This prompt will be passed to Claude in Phase 2 to orchestrate the agents.
...
```

**Updated**: Quality checklist to verify orchestration-prompt.md

```bash
Before finishing, verify:
- [ ] orchestration-prompt.md clearly explains the workflow
- [ ] Orchestration prompt lists all agents and their tasks
```

**Updated**: File save count from 2 to 3

```bash
3. **DO save three files**: research-plan.md, agents.json, and orchestration-prompt.md
```

### Phase 1 Validation (ccheavy.sh:426-442)

**Added**: Validation for orchestration-prompt.md

```bash
if [ ! -f "$OUTPUT_DIR/orchestration-prompt.md" ]; then
    echo -e "${RED}❌ Error: orchestration-prompt.md not generated${NC}"
    exit 1
fi

if [ ! -s "$OUTPUT_DIR/orchestration-prompt.md" ]; then
    echo -e "${RED}❌ Error: orchestration-prompt.md is empty${NC}"
    exit 1
fi
```

**Updated**: Success message to include orchestration file

```bash
echo -e "${BLUE}   🎯 Orchestration: orchestration-prompt.md${NC}"
```

### Phase 2 Launch (ccheavy.sh:552-575)

**Added**: Validation for orchestration-prompt.md

```bash
if [ ! -f "orchestration-prompt.md" ]; then
    echo -e "${RED}❌ Error: orchestration-prompt.md not found${NC}"
    exit 1
fi

if [ ! -r "orchestration-prompt.md" ]; then
    echo -e "${RED}❌ Error: orchestration-prompt.md is not readable${NC}"
    exit 1
fi
```

**Added**: Agent count display

```bash
local agent_count=$(python3 -c "import json; print(len(json.load(open('agents.json'))))" 2>/dev/null || echo "multiple")
echo -e "${CYAN}Loading $agent_count specialized agents...${NC}"
```

**Updated**: Claude launch command to include orchestration prompt

```bash
# Before (broken):
claude --agents "$(cat agents.json)"

# After (fixed):
claude --agents "$(cat agents.json)" "$(cat orchestration-prompt.md)"
```

## How It Works Now

### Phase 1 (Planning - Opus)

```
User: ./ccheavy.sh "What is Rust?" markdown --depth=quick

🤔 Creating research strategy with Opus...
   | Planning in progress...
   ✓ Planning complete!

✅ Research plan generated successfully!
   📊 Agents created: 3
   📄 Plan: research-plan.md
   🤖 Agents: agents.json
   🎯 Orchestration: orchestration-prompt.md  ← NEW
```

**Opus generates:**
1. Research plan (for user review)
2. Agent definitions (system prompts)
3. Orchestration instructions (workflow for Phase 2)

### Phase 2 (Research - Agents + Orchestration)

```
User: Y  (approves plan)

✅ Plan approved!

🚀 Launching specialized research agents...
Loading 3 specialized agents...

[Claude launches with:]
- agents.json       → Agent definitions
- orchestration-prompt.md  → What to do with the agents ← NEW
```

**Claude in Phase 2 now:**
1. Reads orchestration instructions
2. Understands the overall task
3. Creates TodoWrite tasks for each agent
4. Assigns work to each agent sequentially/parallel
5. Each agent executes their research
6. Synthesizes all findings into final-analysis.md

## Example orchestration-prompt.md

```markdown
# Research Orchestration: What is Rust?

You are orchestrating a multi-agent research project.

## Research Question
What is Rust?

## Your Available Agents

- **ra-1-core-language**: Language fundamentals, syntax, memory model
- **ra-2-use-cases**: Real-world applications, adoption patterns
- **ra-3-ecosystem**: Tooling, libraries, community

## Your Orchestration Tasks

### 1. Agent Task Assignment
Use TodoWrite to create tasks:
- [ ] ra-1-core-language: Research Rust fundamentals
- [ ] ra-2-use-cases: Research real-world applications
- [ ] ra-3-ecosystem: Research tooling and ecosystem

### 2. Execute Research Phase
For each agent:
1. Mark task as in_progress
2. Tell agent to execute research
3. Wait for findings file
4. Mark completed

### 3. Synthesis Phase
After all agents complete:
1. Read all findings from ./assistants/
2. Synthesize into comprehensive analysis
3. Save to ./final-analysis.md

## Expected Outputs
- ./assistants/ra-1-core-language-findings.md
- ./assistants/ra-2-use-cases-findings.md
- ./assistants/ra-3-ecosystem-findings.md
- ./final-analysis.md (you create this)

Begin orchestration now!
```

## Testing

### Syntax Validation
```bash
bash -n ccheavy.sh
# ✅ No syntax errors
```

### Phase 1 Test (to be done)
Will verify that Phase 1 now generates all three files:
- research-plan.md ✓
- agents.json ✓
- orchestration-prompt.md ✓ (NEW)

### Phase 2 Test (to be done)
Will verify that Phase 2 launches with orchestration instructions and agents execute properly.

## Benefits

### Before (Broken)
```
Phase 2: claude --agents "$(cat agents.json)"
         ↓
Claude: "I have these agent definitions... but what do I do with them?"
Result: Agents don't execute, or execute incorrectly
```

### After (Fixed)
```
Phase 2: claude --agents "$(cat agents.json)" "$(cat orchestration-prompt.md)"
         ↓
Claude: "I have agents AND orchestration instructions!"
        "I need to assign ra-1 to task X, ra-2 to task Y..."
        "Execute agents, collect findings, synthesize results"
Result: Agents execute properly with clear task assignments
```

## Impact

| Aspect | Before | After |
|--------|--------|-------|
| **Files Generated** | 2 (plan + agents) | 3 (plan + agents + orchestration) |
| **Phase 2 Context** | Only agent definitions | Definitions + workflow instructions |
| **Task Assignment** | Unclear/missing | Explicit with TodoWrite tracking |
| **Coordination** | No guidance | Step-by-step workflow |
| **Expected Outputs** | Not specified | Clearly listed |
| **Agent Execution** | Broken/unclear | Working with proper assignments |

## Lines of Code Changed

- **Added**: ~90 lines (orchestration template in Phase 1 prompt)
- **Modified**: ~30 lines (validation + Phase 2 launch)
- **Total Impact**: ~120 lines

## Next Steps

1. ✅ Syntax validated (no errors)
2. ⏳ Test Phase 1 to verify orchestration-prompt.md generation
3. ⏳ Test Phase 2 to verify agents execute with task assignments
4. ⏳ Verify final-analysis.md is created properly
5. ⏳ Update documentation (CLAUDE.md, README.md)

## Conclusion

This fix addresses the critical issue where agents weren't being assigned tasks in Phase 2. By generating an orchestration-prompt.md in Phase 1 and passing it to Claude alongside agents.json in Phase 2, we provide clear instructions on:

- What the overall research task is
- Which agent works on which part
- How to coordinate between agents
- What the expected workflow and outputs are

**Status**: 🔧 **Fix Implemented** - Ready for testing

**Version**: 2.3 (Orchestration Fix)

**Date**: November 10, 2025
