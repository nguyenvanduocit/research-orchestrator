# Transparent Two-Phase Architecture

## 🎯 User Experience (Completely Seamless)

**User runs:**
```bash
./ccheavy.sh "Should we migrate to PostgreSQL?" markdown --depth=deep
```

**What happens automatically:**

```
╔═══════════════════════════════════════════╗
║   Claude Code Heavy v2.0 Research      ║
╚═══════════════════════════════════════════╝

═══ Configuration ═══
  Query: Should we migrate to PostgreSQL?
  Depth: deep (~40 minutes)
  Assistants: 6-8 recommended
  Output: ./outputs/2025-11-10-should-we-migrate-to-postgresql
═══════════════════════

🤔 Creating research strategy with Opus...

✅ Research plan generated!

═══ Research Strategy ═══

**Research Approach**: Decision Support Analysis
**Assistants**: 6 specialized agents + verification

1. RA-1: Current State Analyst
   Focus: Existing MongoDB setup, pain points, requirements

2. RA-2: PostgreSQL Architecture Expert
   Focus: PostgreSQL capabilities, ACID guarantees, data modeling

3. RA-3: Migration Cost Analyst
   Focus: Migration effort, timeline, costs, risks

4. RA-4: Performance Evaluator
   Focus: Performance comparison, benchmarks, workload analysis

5. RA-5: Ecosystem & Tooling Researcher
   Focus: Tools, libraries, team expertise requirements

6. RA-6: Decision Framework Specialist
   Focus: Decision criteria, trade-offs, recommendations

7. RA-V: Verification Assistant (cross-checks findings)

═══════════════════════

📋 Review this plan:
  [Y/Enter] Proceed with research
  [n] Cancel
  [Any other text] Provide feedback to improve plan

Your choice: _
```

**User Options:**

### Option 1: User presses Y or Enter
```
✅ Plan approved!

🚀 Launching specialized research agents...

[Interactive Claude session starts with agents.json]
Each agent conducts research autonomously...
```

### Option 2: User provides feedback
```
Your choice: Focus more on data consistency and less on performance

🔄 Refining research strategy based on your feedback...

✅ Updated research plan generated!

═══ Updated Research Strategy ═══

**Research Approach**: Data Consistency Focus
**Assistants**: 6 specialized agents + verification

1. RA-1: Data Consistency Expert (NEW FOCUS)
   Focus: ACID vs BASE, consistency guarantees, transaction handling

2. RA-2: PostgreSQL Architecture Expert
   Focus: PostgreSQL transaction model, isolation levels

...

📋 Review this updated plan:
  [Y/Enter] Proceed
  [n] Cancel
  [feedback] Refine further

Your choice: _
```

### Option 3: User types 'n'
```
❌ Cancelled.
```

---

## 🏗️ Technical Implementation

### Script Flow

```bash
#!/bin/bash

# ... setup code ...

# PHASE 1: Strategy & Agent Declaration (Invisible to User)
run_phase1() {
    local feedback="${1:-}"

    echo -e "${CYAN}🤔 Creating research strategy with Opus...${NC}"
    echo

    # Create Phase 1 prompt (planning-only)
    create_phase1_prompt "$feedback"

    # Auto-launch with Opus (non-interactive, dangerously-skip-permissions)
    claude --model opus --dangerously-skip-permissions \
          "$PHASE1_PROMPT" > "$OUTPUT_DIR/.phase1-output.txt" 2>&1

    # Verify outputs were created
    if [ ! -f "$OUTPUT_DIR/research-plan.md" ] || [ ! -f "$OUTPUT_DIR/agents.json" ]; then
        echo -e "${RED}Error: Phase 1 failed to generate required files${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Research plan generated!${NC}"
    echo
}

# Show plan and get user approval
get_user_approval() {
    echo -e "${MAGENTA}═══ Research Strategy ═══${NC}"
    echo

    # Display research-plan.md (formatted)
    cat "$OUTPUT_DIR/research-plan.md"

    echo
    echo -e "${MAGENTA}═══════════════════════${NC}"
    echo
    echo -e "${BLUE}📋 Review this plan:${NC}"
    echo -e "  ${GREEN}[Y/Enter]${NC} Proceed with research"
    echo -e "  ${RED}[n]${NC} Cancel"
    echo -e "  ${YELLOW}[Any other text]${NC} Provide feedback to improve plan"
    echo
    read -r -p "Your choice: " user_response

    echo "$user_response"
}

# PHASE 2: Research Execution (Invisible to User)
run_phase2() {
    echo
    echo -e "${GREEN}✅ Plan approved!${NC}"
    echo
    echo -e "${CYAN}🚀 Launching specialized research agents...${NC}"
    echo

    # Launch with agents.json interactively
    cd "$OUTPUT_DIR"
    claude --agents "$(cat agents.json)"
}

# Main execution loop
main() {
    # ... setup ...

    # Run Phase 1 (initial)
    run_phase1

    # User approval loop
    while true; do
        response=$(get_user_approval)

        if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
            # Approved - run Phase 2
            run_phase2
            break

        elif [[ "$response" =~ ^[Nn]$ ]]; then
            # Cancelled
            echo -e "${YELLOW}❌ Cancelled.${NC}"
            exit 0

        else
            # Feedback provided - re-run Phase 1
            echo
            echo -e "${CYAN}🔄 Refining research strategy based on your feedback...${NC}"
            echo
            run_phase1 "$response"
        fi
    done
}

main
```

---

## 📝 Phase 1 Prompt (Planning-Only)

The Phase 1 prompt must:
1. Generate `research-plan.md`
2. Generate `agents.json`
3. NOT execute any research

```markdown
# Phase 1: Strategic Planning & Agent Declaration

You are creating a research strategy and defining specialized agents.
DO NOT execute research yet - that happens in Phase 2.

## Query
$QUERY

## Configuration
- Depth: $RESEARCH_DEPTH
- Assistants: $MIN_ASSISTANTS-$MAX_ASSISTANTS_RECOMMENDED
- Word Count: $WORD_COUNT per assistant
- Focus: $FOCUS_AREAS
- Verification: $INCLUDE_VERIFICATION

$(if [ -n "$USER_FEEDBACK" ]; then
echo "## User Feedback from Previous Plan
$USER_FEEDBACK

Please incorporate this feedback into your planning."
fi)

## Your Tasks

### 1. Create Research Plan (research-plan.md)

Include:
- Research approach/strategy
- Number of agents and rationale
- Each agent's role and focus
- Expected coverage
- Research templates applied

Format for display to user (they'll review this):
\`\`\`markdown
**Research Approach**: [Approach name]
**Assistants**: [N] specialized agents + verification

1. RA-1: [Role Title]
   Focus: [What this agent researches]

2. RA-2: [Role Title]
   Focus: [What this agent researches]

...
\`\`\`

### 2. Create Agent Definitions (agents.json)

Generate a valid JSON file with specialized agent definitions.

**CRITICAL**: Each agent must have:
- `description`: One-line description (for system)
- `prompt`: Full custom system prompt (200-400 words)

**Agent System Prompt Template**:
\`\`\`
You are [ROLE], a specialized research assistant.

## Your Assignment
Research Question: [Specific focused question]

## Your Expertise
- [Domain area 1]
- [Domain area 2]
- [Domain area 3]

## Quality Standards (MANDATORY)
- **Citations**: Include [source URL] for every claim
- **Confidence**: Mark findings with 🟢 HIGH, 🟡 MEDIUM, 🔴 LOW
- **Sources**: Use 3-5 different sources per major claim
- **Recency**: Prioritize 2024-2025 data
- **Gaps**: Acknowledge what you couldn't find

## Output Requirements
Save findings to: ./assistants/ra-[N]-findings.md

Use this structure:
[Standard report structure...]

## Search Strategy
Start with these parallel searches:
- "[suggested query 1]"
- "[suggested query 2]"
- "[suggested query 3]"

If poor results, adapt:
- Try alternative terminology
- Broaden/narrow scope
- Look for case studies

Word Count: $WORD_COUNT
Focus: $FOCUS_AREAS
\`\`\`

**Example agents.json**:
\`\`\`json
{
  "ra-1-performance-analyst": {
    "description": "Analyzes PostgreSQL vs MongoDB performance characteristics",
    "prompt": "You are a Performance Analyst specializing in database systems...\\n\\n[full prompt]"
  },
  "ra-2-migration-specialist": {
    "description": "Evaluates migration complexity, costs, and timeline",
    "prompt": "You are a Migration Specialist...\\n\\n[full prompt]"
  }
  $([ "$INCLUDE_VERIFICATION" = "true" ] && echo ',
  "ra-v-verification": {
    "description": "Cross-verifies findings from all research assistants",
    "prompt": "You are a Verification Assistant...\\n\\n[full prompt]"
  }')
}
\`\`\`

## Important Notes

1. **DO NOT execute research** - only create the plan and agents
2. **Use research templates** from your knowledge (Comparative Analysis, Decision Support, etc.)
3. **Incorporate user feedback** if provided
4. **Validate JSON** - ensure agents.json is valid
5. **Clear focus** - each agent has non-overlapping responsibility
6. **Embedded standards** - quality controls in every agent prompt

## Output Files

Save exactly two files:
1. `./research-plan.md` (user-friendly, will be displayed)
2. `./agents.json` (machine-readable, will be used in Phase 2)

Begin!
```

---

## 🎨 User Interface Polish

### Loading Indicators
```bash
echo -e "${CYAN}🤔 Creating research strategy with Opus...${NC}"
# Show spinner while Phase 1 runs
while [ ! -f "$OUTPUT_DIR/research-plan.md" ]; do
    echo -n "."
    sleep 1
done
echo
```

### Pretty Plan Display
```bash
# Parse and format research-plan.md for display
display_research_plan() {
    # Extract key sections
    # Format with colors
    # Add visual separators
}
```

### Feedback Loop
```bash
# If user provides feedback, show it's being incorporated
echo -e "${CYAN}🔄 Refining based on: \"$user_feedback\"${NC}"
```

---

## 🧪 Testing Scenarios

### Scenario 1: Happy Path (Approve Immediately)
```
User: ./ccheavy.sh "Test query" markdown
[Phase 1 runs]
[Plan displayed]
User: Y
[Phase 2 runs with agents]
```

### Scenario 2: Refinement Loop
```
User: ./ccheavy.sh "Test query" markdown
[Phase 1 runs]
[Plan displayed]
User: Focus more on costs
[Phase 1 re-runs with feedback]
[Updated plan displayed]
User: Y
[Phase 2 runs with updated agents]
```

### Scenario 3: Cancel
```
User: ./ccheavy.sh "Test query" markdown
[Phase 1 runs]
[Plan displayed]
User: n
Script: ❌ Cancelled
```

---

## 📊 Benefits

### User Perspective
- **Simple**: One command, intelligent workflow
- **Transparent**: See plan before research starts
- **Controllable**: Can refine strategy
- **No mental overhead**: Don't need to know about phases

### Technical Perspective
- **Better planning**: Opus focus on strategy
- **True specialization**: Real Claude Code agents
- **Reproducible**: agents.json can be saved/reused
- **Debuggable**: Can inspect Phase 1 output

---

## 🚀 Next Steps

1. Create `create_phase1_prompt()` function
2. Implement `run_phase1()` with Opus auto-launch
3. Add `get_user_approval()` with formatted display
4. Implement feedback loop
5. Add `run_phase2()` with agents.json
6. Test end-to-end workflow
7. Polish UI (spinners, colors, formatting)

---

**Status**: Architecture designed, ready for implementation
**Complexity**: Medium-High (feedback loop, file watching)
**User Impact**: Massively improved UX - completely seamless
