# Two-Phase Architecture Implementation Plan

## 🎯 Vision: Separated Planning and Execution

Your suggestion to split into two phases is **architecturally superior**:

### Phase 1: Strategic Planning (Non-interactive, Opus)
```bash
./ccheavy.sh "query" markdown --depth=deep --phase=plan
```
- **Model**: Opus (superior strategic thinking)
- **Mode**: Non-interactive, auto-executes
- **Permissions**: `--dangerously-skip-permissions` (safe for planning)
- **Output**:
  - `research-plan.md` (research strategy)
  - `agents.json` (**critical**: agent definitions)
  - `orchestration-details.md` (optional)

### Phase 2: Research Execution (Interactive, with Agents)
```bash
cd outputs/[date]-[query]/
claude --agents $(cat agents.json)
```
- **Model**: Per-agent (from agents.json)
- **Mode**: Interactive (user can monitor)
- **Input**: Uses `agents.json` from Phase 1
- **Output**: All research findings

---

## 🏗️ Implementation Status

### ✅ Already Done
1. Added `--phase` parameter to script
2. Added `EXECUTION_PHASE` variable (all/plan/research)
3. Updated banner to show phase
4. Agent Declaration phase documented in prompts
5. agents.json format and template defined

### 🚧 Still Needed

#### 1. Phase 1 Prompt (Planning-Only)
Create dedicated prompt that:
- Focuses ONLY on strategic planning
- **Must generate `agents.json` file**
- Provides agent system prompt templates
- Does NOT execute research
- Optimized for Opus strategic thinking

#### 2. Auto-Launch Logic for Phase 1
```bash
if [ "$EXECUTION_PHASE" = "plan" ]; then
    # Auto-launch with Opus
    claude --model opus --dangerously-skip-permissions \
          "$(cat $PROMPT_FILE)"
fi
```

#### 3. Phase 2 Instructions
When running `--phase=research`, provide instructions:
```
Phase 2: Research Execution

To execute research with your specialized agents:

1. Navigate to research directory:
   cd ./outputs/[date]-[query]/

2. Launch Claude with agents:
   claude --agents $(cat agents.json)

3. Each agent will autonomously:
   - Execute specialized research
   - Follow embedded quality standards
   - Save findings to designated files

4. After agents complete, synthesize findings
```

---

## 📋 Detailed Implementation Steps

### Step 1: Create Phase 1 Prompt Template

**Key Requirements**:
- Must instruct to create `agents.json` file
- Provide detailed agent definition template
- Focus on quality of agent system prompts
- Include model recommendations per agent
- Output research-plan.md

**Prompt Structure**:
```markdown
# Phase 1: Strategic Planning & Agent Declaration

Your task: Create a comprehensive research plan and define specialized agents.

## Outputs Required

### 1. Research Plan (research-plan.md)
- Query analysis
- Research strategy
- Number of assistants
- Coverage areas

### 2. Agent Definitions (agents.json) ***CRITICAL***

You MUST create agents.json with this structure:

```json
{
  "ra-1-role-slug": {
    "description": "One-line description",
    "prompt": "Full agent system prompt with:\n- Expertise areas\n- Research question\n- Quality standards\n- Output requirements\n- Search strategies"
  },
  ...
}
```

**Agent System Prompt Template**:
```
You are [ROLE], specialized research assistant.

Research Question: [specific focused question]

Expertise:
- [domain 1]
- [domain 2]

Quality Standards:
- Citations with URLs
- Confidence markers (🟢🟡🔴)
- 3-5 sources per claim

Output: Save findings to ./assistants/ra-N-findings.md

Search Strategy:
- [suggested query 1]
- [suggested query 2]
```

## Important Notes

- Each agent prompt should be 200-400 words
- Include specific search query suggestions
- Embed quality standards in each agent
- Verify agent (if deep mode) should reference all other agents

**Do NOT execute research in Phase 1. Only plan and define agents.**
```

### Step 2: Modify Script Launch Logic

Add conditional logic after prompt generation:

```bash
# After generating PROMPT_FILE

if [ "$EXECUTION_PHASE" = "plan" ]; then
    # Phase 1: Auto-launch with Opus for planning
    echo -e "${MAGENTA}═══ Phase 1: Strategic Planning ═══${NC}"
    echo -e "  ${CYAN}Launching Opus for strategic planning...${NC}"
    echo -e "  ${CYAN}Generating: research-plan.md + agents.json${NC}"
    echo

    # Auto-launch with Opus
    claude --model opus --dangerously-skip-permissions \
          --chat "$(cat "$PROMPT_FILE")"

    echo
    echo -e "${GREEN}✅ Phase 1 Complete!${NC}"
    echo
    echo -e "${MAGENTA}═══ Generated Artifacts ═══${NC}"
    echo -e "  ${YELLOW}Research Plan:${NC} $OUTPUT_DIR/research-plan.md"
    echo -e "  ${YELLOW}Agent Definitions:${NC} $OUTPUT_DIR/agents.json"
    echo
    echo -e "${BLUE}══ Next Step: Phase 2 (Research Execution) ══${NC}"
    echo
    echo -e "To execute research with your specialized agents:"
    echo
    echo -e "  ${GREEN}cd $OUTPUT_DIR${NC}"
    echo -e "  ${GREEN}claude --agents \$(cat agents.json)${NC}"
    echo
    echo -e "Each agent will autonomously research their assigned topic."
    echo

elif [ "$EXECUTION_PHASE" = "research" ]; then
    # Phase 2: Provide instructions for using agents

    AGENTS_FILE="$OUTPUT_DIR/agents.json"

    if [ ! -f "$AGENTS_FILE" ]; then
        echo -e "${RED}Error: agents.json not found!${NC}"
        echo -e "${YELLOW}Run Phase 1 first: ${NC}$0 \"$QUERY\" $OUTPUT_FORMAT --phase=plan"
        exit 1
    fi

    echo -e "${MAGENTA}═══ Phase 2: Research Execution ═══${NC}"
    echo
    echo -e "Agent definitions loaded from: ${CYAN}$AGENTS_FILE${NC}"
    echo
    echo -e "Launch research with:"
    echo -e "  ${GREEN}cd $OUTPUT_DIR${NC}"
    echo -e "  ${GREEN}claude --agents \$(cat agents.json)${NC}"
    echo

else
    # Phase "all": Current behavior (backward compatible)
    # ... existing launch logic ...
fi
```

### Step 3: Update CLAUDE.md Documentation

Add section explaining two-phase workflow:

```markdown
## Two-Phase Execution (Recommended for Complex Research)

For better separation of strategy and execution:

### Phase 1: Planning (Non-interactive, Opus)
```bash
./ccheavy.sh "Should we migrate to PostgreSQL?" markdown \
  --depth=deep --phase=plan
```

- Opus creates strategic plan
- Generates `agents.json` with specialized agent definitions
- Non-interactive, auto-executes
- Output: research-plan.md, agents.json

### Phase 2: Research (Interactive, with Agents)
```bash
cd outputs/[date]-[query]/
claude --agents $(cat agents.json)
```

- Launches specialized agents
- Interactive mode (monitor progress)
- Each agent researches autonomously
- Higher quality through specialization
```

---

## 🎯 Benefits of Two-Phase Approach

### Strategic Benefits
1. **Better Planning**: Opus focuses purely on strategy
2. **True Specialization**: Each agent has custom system prompt
3. **Reproducibility**: agents.json can be reused/modified
4. **Cost Optimization**: Opus only for planning, not full research

### Operational Benefits
1. **Non-interactive Planning**: Can be automated
2. **Interactive Research**: User monitors execution
3. **Parallel Execution**: Agents work simultaneously
4. **Intervention**: Can stop/adjust during Phase 2

### Quality Benefits
1. **Specialized Agents**: Each agent is an expert in their domain
2. **Embedded Standards**: Quality controls in agent prompts
3. **Better Isolation**: Agents don't interfere with each other
4. **Proper Tool Access**: Each agent has full Claude Code capabilities

---

## 🔄 Workflow Example

### Scenario: "Should we adopt GraphQL?"

**Step 1: Generate Plan and Agents**
```bash
./ccheavy.sh "Should we adopt GraphQL?" markdown \
  --depth=deep --focus=performance,complexity --phase=plan
```

Output:
- `research-plan.md`: Strategic approach, 6 agents identified
- `agents.json`: Definitions for:
  - ra-1-performance-expert
  - ra-2-complexity-analyst
  - ra-3-ecosystem-researcher
  - ra-4-migration-specialist
  - ra-5-alternative-evaluator
  - ra-v-verification

**Step 2: Execute Research**
```bash
cd outputs/2025-11-10-should-we-adopt-graphql/
claude --agents $(cat agents.json)
```

Claude launches with 6 specialized agents, each:
- Has custom system prompt
- Knows their specific research question
- Has embedded quality standards
- Suggests initial search queries

User can:
- Monitor progress
- Intervene if needed
- Ask questions during research

---

## 🚀 Implementation Priority

### High Priority (Core Functionality)
1. ✅ Add --phase parameter
2. ⏳ Create Phase 1 prompt template
3. ⏳ Implement auto-launch for Phase 1
4. ⏳ Add Phase 2 instructions

### Medium Priority (User Experience)
5. Update documentation (CLAUDE.md, README.md)
6. Add examples showing two-phase workflow
7. Error handling (agents.json not found, etc.)

### Low Priority (Nice to Have)
8. Validate agents.json format
9. Allow editing agents.json between phases
10. Phase 1 summary statistics

---

## 🧪 Testing Plan

### Test Case 1: Quick Research
```bash
./ccheavy.sh "What is WebAssembly?" markdown --depth=quick --phase=plan
# Verify: research-plan.md, agents.json with 2-3 agents
cd outputs/*/
claude --agents $(cat agents.json)
# Verify: Each agent executes, saves findings
```

### Test Case 2: Deep Research
```bash
./ccheavy.sh "PostgreSQL vs MongoDB migration?" markdown \
  --depth=deep --focus=costs,risks --phase=plan
# Verify: agents.json with 6-8 agents + verification agent
cd outputs/*/
claude --agents $(cat agents.json)
# Verify: Agents execute in parallel, verification runs last
```

### Test Case 3: Backward Compatibility
```bash
./ccheavy.sh "Quick query" markdown --depth=standard
# Verify: Original single-phase behavior still works
```

---

## 💡 Advanced Features (Future)

### Agent Editing Between Phases
```bash
# After Phase 1, user can edit agents.json
vim outputs/[date]-[query]/agents.json
# Then proceed to Phase 2
```

### Agent Templates Library
Pre-defined agent configurations for common scenarios:
- comparative-analysis-agents.json
- impact-assessment-agents.json
- technical-deep-dive-agents.json

### Phase 1 Dry Run
```bash
./ccheavy.sh "query" --phase=plan --dry-run
# Shows what would be generated without executing
```

---

## 📝 Next Steps

1. **Implement Phase 1 Prompt**: Create planning-focused prompt template
2. **Add Auto-Launch Logic**: Implement conditional launch based on phase
3. **Test Two-Phase Flow**: Verify end-to-end workflow
4. **Update Documentation**: Add two-phase examples to all docs
5. **Create Examples**: Show real agents.json from Phase 1

---

**Status**: Ready for implementation
**Estimated Effort**: 2-3 hours
**Impact**: Transforms research quality through proper specialization
