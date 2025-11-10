#!/bin/bash
# ccheavy.sh - Claude Code Heavy Research System
# Multi-agent research orchestration with quality controls

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
MAX_ASSISTANTS=8
VERSION="2.0"

# Check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v claude &> /dev/null; then
        missing_deps+=("claude")
    fi

    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  ${YELLOW}• $dep${NC}"
        done
        echo
        if [[ " ${missing_deps[@]} " =~ " claude " ]]; then
            echo -e "${BLUE}Install Claude Code:${NC}"
            echo -e "  Visit: https://claude.com/claude-code"
        fi
        exit 1
    fi
}

# Generate concise folder name using Haiku
generate_folder_name() {
    local query="$1"

    echo -e "${CYAN}📝 Generating folder name...${NC}" >&2

    # Create prompt for Haiku to generate concise folder name
    local haiku_prompt="Generate a concise folder name (2-4 words, lowercase, hyphen-separated) for this research query:

\"$query\"

Requirements:
- 2-4 words maximum
- Lowercase only
- Use hyphens between words (e.g., hidden-poe-apis)
- Descriptive but brief
- No special characters except hyphens
- Must be a valid folder name

Respond with ONLY the folder name, nothing else.

Examples:
Query: \"What are the best practices for React hooks?\"
Folder: react-hooks-best-practices

Query: \"How does Bitcoin mining work?\"
Folder: bitcoin-mining-explained

Query: \"Looking for some hidden API that Claude does not tell us\"
Folder: hidden-claude-apis

Now generate the folder name:"

    # Call Haiku to generate folder name
    local folder_name=$(claude --model haiku --dangerously-skip-permissions "$haiku_prompt" 2>/dev/null | tail -1 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    # Validate the folder name
    # Remove any remaining invalid characters
    folder_name=$(echo "$folder_name" | sed 's/[^a-z0-9-]//g')

    # Ensure it's not empty and not too long
    if [ -z "$folder_name" ] || [ ${#folder_name} -lt 3 ]; then
        # Fallback to simple sanitization if Haiku fails
        echo -e "${YELLOW}⚠️  Haiku generation failed, using fallback...${NC}" >&2
        folder_name=$(echo "$query" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)
    fi

    # Truncate if still too long
    if [ ${#folder_name} -gt 50 ]; then
        folder_name="${folder_name:0:50}"
        # Remove trailing partial word
        folder_name=$(echo "$folder_name" | sed 's/-[^-]*$//')
    fi

    echo -e "${GREEN}✓ Folder name: ${folder_name}${NC}" >&2

    # Return the folder name
    echo "$folder_name"
}

# Create Phase 1 prompt (planning-only, generates agents.json)
create_phase1_prompt() {
    local feedback="$1"
    local prompt_file="$OUTPUT_DIR/.phase1-prompt.md"

    local feedback_section=""
    if [ -n "$feedback" ]; then
        feedback_section="
## User Feedback from Previous Plan

\`\`\`
$feedback
\`\`\`

**Please incorporate this feedback into your planning.** Adjust agent roles, focus areas, or approach based on what the user wants."
    fi

    cat > "$prompt_file" << 'PHASE1_EOF'
# Phase 1: Strategic Planning & Agent Declaration

You are creating a research strategy and defining specialized agents.
**DO NOT execute research yet** - that happens in Phase 2.

## Query
PHASE1_EOF
    echo "$QUERY" >> "$prompt_file"

    cat >> "$prompt_file" << PHASE1_EOF

## Configuration
- Depth: $RESEARCH_DEPTH
- Recommended Assistants: $MIN_ASSISTANTS-$MAX_ASSISTANTS_RECOMMENDED
- Word Count per Assistant: $WORD_COUNT
$([ -n "$FOCUS_AREAS" ] && echo "- Focus Areas: $FOCUS_AREAS")
- Verification Required: $INCLUDE_VERIFICATION
$feedback_section

## Your Tasks

### Task 1: Create Research Plan

Save to: \`$OUTPUT_DIR/research-plan.md\`

This will be shown to the user for approval. Format it clearly:

\`\`\`markdown
# Research Strategy: [Query Title]

## Research Approach
[Name of approach: Comparative Analysis, Decision Support, Impact Analysis, etc.]

## Assistants Overview
**Total**: [N] specialized agents$([ "$INCLUDE_VERIFICATION" = "true" ] && echo " + 1 verification agent")

## Agent Assignments

### 1. RA-1: [Role Title]
**Focus**: [What this agent researches - 1-2 sentences]
**Key Questions**: [2-3 specific questions this agent will answer]

### 2. RA-2: [Role Title]
**Focus**: [What this agent researches]
**Key Questions**: [Questions]

[Continue for all agents...]

$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "### RA-V: Verification Assistant
**Focus**: Cross-verify findings from all research assistants
**Key Questions**: Are claims properly sourced? Any contradictions? Bias detected?")

## Expected Coverage
- [Coverage area 1]
- [Coverage area 2]
- [Coverage area 3]

## Research Templates Applied
[Which template(s) from your knowledge: Comparative, Impact, Technical Deep Dive, etc.]
\`\`\`

**Make it user-friendly** - they need to understand and approve this plan.

### Task 2: Create Agent Definitions

Save to: \`$OUTPUT_DIR/agents.json\`

Generate valid JSON with specialized agent definitions.

**Agent JSON Structure**:
\`\`\`json
{
  "ra-1-role-slug": {
    "description": "One-line description of what this agent researches",
    "prompt": "Full custom system prompt (see template below)"
  },
  "ra-2-role-slug": {
    "description": "One-line description",
    "prompt": "Full custom system prompt"
  }
  $([ "$INCLUDE_VERIFICATION" = "true" ] && echo ',
  "ra-v-verification": {
    "description": "Cross-verifies findings from all research assistants",
    "prompt": "Verification assistant system prompt"
  }')
}
\`\`\`

**Agent System Prompt Template** (200-400 words each):

\`\`\`
You are [ROLE], a specialized research assistant for: "$QUERY"

## Your Specific Assignment

Research Question: [The focused question this agent must answer]

## Your Expertise
- [Domain knowledge area 1]
- [Domain knowledge area 2]
- [Domain knowledge area 3]

## Quality Standards (MANDATORY)

Every finding must include:
- **Citations**: [source URL] for EVERY claim
- **Confidence**: 🟢 HIGH (multiple sources), 🟡 MEDIUM (single source), 🔴 LOW (limited data)
- **Sources**: Use 3-5 different sources per major claim
- **Recency**: Prioritize 2024-2025 data, note older information
- **Gaps**: Explicitly state what you couldn't find

## Output Requirements

Save your findings to: \`$OUTPUT_DIR/assistants/ra-[N]-[role-slug]-findings.md\`

**Required Structure**:
\`\`\`markdown
# Research Assistant [N]: [Your Role]

## Assignment
[Your research question]

## Key Findings
[3-5 main discoveries with 🟢🟡🔴 confidence indicators]

## Detailed Analysis
[$WORD_COUNT words with inline citations]

## Confidence Assessment
- High confidence claims: [X]
- Medium confidence claims: [Y]
- Low confidence claims: [Z]

## Gaps & Limitations
[What you couldn't find or verify]

## Sources
1. [Title](URL) - Accessed [Date]
2. [Title](URL) - Accessed [Date]
...
\`\`\`

## Search Strategy

Start with parallel WebSearch calls for efficiency:
1. "[Suggested search query 1 specific to this agent's focus]"
2. "[Suggested search query 2]"
3. "[Suggested search query 3]"

If searches yield poor results:
- Try alternative terminology
- Broaden or narrow scope
- Look for case studies, not just technical docs
- Search for "[specific topic]" + "case study" or "real world"

$([ -n "$FOCUS_AREAS" ] && echo "**Priority Focus**: $FOCUS_AREAS")
\`\`\`

**Important for Agent Prompts**:
1. Be specific about what each agent researches
2. Include 2-3 suggested initial search queries
3. Embed all quality standards
4. Make expertise clear
5. Non-overlapping responsibilities

$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "**Verification Agent Special Instructions**:
The verification agent should:
- Read ALL other assistants' findings files
- Cross-check key statistical claims
- Identify contradictions between assistants
- Flag single-source claims that need more verification
- Check for potential bias or missing perspectives")

### Task 3: Create Orchestration Prompt

Save to: \`./orchestration-prompt.md\`

This prompt will be passed to Claude in Phase 2 to orchestrate the agents. It must include:

\`\`\`markdown
# Research Orchestration: [Query Title]

You are orchestrating a multi-agent research project with specialized agents.

## Research Question
$QUERY

## Current Status - What's Already Done ✅

**Phase 1 (Planning) has been completed by Opus. The following are ready:**

✅ **Research plan created**
- File: ./research-plan.md
- Contains: Strategy, agent assignments, coverage areas
- Status: Complete and approved by user

✅ **Specialized agents defined**
- File: ./agents.json
- Contains: [N] agents with custom system prompts
- Each agent has: Role, expertise, assignment, quality standards, search strategies

✅ **Output directory structure ready**
- Directory: $OUTPUT_DIR
- Subdirectory: ./assistants/ (for agent findings)
- All file paths configured

✅ **Orchestration instructions prepared**
- This file: ./orchestration-prompt.md
- Contains: Your workflow, checklists, guidelines

## 🎯 Your Starting Point - Begin Here

**You are now in Phase 2: Research Execution**

Your first action should be:
1. Read the research-plan.md to understand the strategy
2. Review agents.json to see your available agents
3. Use TodoWrite to create tasks for ALL agents
4. Then proceed through the orchestration workflow below

## Your Available Agents

[List each agent with their role and what they research]

Example:
- **ra-1-[role-slug]**: [One line describing what this agent researches]
- **ra-2-[role-slug]**: [One line describing what this agent researches]
...

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

## Your Orchestration Workflow

Follow these phases in order. Use TodoWrite to track progress.

### Phase 1: Understand Context & Create Tasks

**What's already done (just review):**
- ✅ Research plan exists in ./research-plan.md
- ✅ Agents defined in ./agents.json
- ✅ Output directory structure ready

**Your action items (do these now):**

**Checklist:**
- [ ] Read ./research-plan.md to understand the strategy
- [ ] Review ./agents.json to see all available agents
- [ ] **Use TodoWrite to create a task for EVERY agent**
- [ ] Add a final task for synthesis
- [ ] Confirm all agents have clear, non-overlapping focus

**Example TodoWrite tasks:**
\\\`\\\`\\\`
- [ ] ra-1-[role]: [Brief description of what this agent researches]
- [ ] ra-2-[role]: [Brief description of what this agent researches]
- [ ] ra-N-[role]: [Brief description of what this agent researches]
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- [ ] ra-v-verification: Cross-verify all agent findings")
- [ ] Synthesize final analysis from all agent findings
\\\`\\\`\\\`

**Important:** Create TodoWrite tasks for ALL agents before starting any research.

### Phase 2: Agent Research Execution

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

### Phase 3: Verification (if required)

$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "**Checklist:**
- [ ] Confirm all agent findings files exist in ./assistants/
- [ ] Mark ra-v-verification task as in_progress
- [ ] Tell verification agent to:
  - Read ALL agent findings files
  - Cross-check statistical claims
  - Identify contradictions between sources
  - Flag single-source claims needing verification
  - Check for bias or missing perspectives
- [ ] Verify ra-v-verification-findings.md was created
- [ ] Mark ra-v-verification task as completed" || echo "**Not required for this research depth.**
Skip to Phase 4.")

### Phase 4: Synthesis and Final Analysis

**Important Decision: Choose your approach based on report size**

#### Approach A: Standard Synthesis (for normal-length reports)

**Use when:**
- Quick or Standard depth research
- 5 or fewer agents
- Total findings expected < 5000 words

**Checklist:**
- [ ] Mark synthesis task as in_progress
- [ ] Read ALL findings files from ./assistants/ directory
- [ ] Create comprehensive final-analysis.md with all sections at once:
  - [ ] Executive Summary (2-3 paragraphs)
  - [ ] Research Methodology section
  - [ ] Detailed Findings (organized by themes)
  - [ ] Cross-Cutting Insights
  - [ ] Limitations & Gaps
  - [ ] Areas of Uncertainty
  - [ ] Recommendations (if applicable)
  - [ ] Complete Bibliography (all sources, deduplicated)
- [ ] Save complete file to: ./final-analysis.md
- [ ] Mark synthesis task as completed

#### Approach B: Incremental Synthesis (for long reports ONLY)

**Use when:**
- Deep research with 6+ agents
- Each agent wrote 1000+ words
- Expected final report > 8000 words
- Risk of hitting token limits

**Checklist:**

**Step 1: Create Outline**
- [ ] Mark synthesis task as in_progress
- [ ] Read ALL findings files to understand scope
- [ ] Estimate total report length
- [ ] Create detailed outline in ./final-analysis-outline.md with:
  - [ ] Section structure
  - [ ] Which agent findings go in which section
  - [ ] Estimated word count per section
  - [ ] Themes identified

**Step 2: Write Sections Incrementally**
- [ ] Start with skeleton file (headers only) in ./final-analysis.md
- [ ] Write Executive Summary section first
  - Read relevant findings
  - Write 2-3 paragraph summary
  - Append to final-analysis.md
- [ ] Write Research Methodology section
  - Document process, agents, configuration
  - Append to final-analysis.md
- [ ] Write Detailed Findings sections (one theme at a time)
  - For each theme:
    - Read relevant agent findings
    - Synthesize theme section
    - Include citations and confidence markers
    - Append to final-analysis.md
- [ ] Write Cross-Cutting Insights section
  - Identify patterns across themes
  - Append to final-analysis.md
- [ ] Write Limitations & Gaps section
  - Compile from all agent reports
  - Append to final-analysis.md
- [ ] Write Areas of Uncertainty section
  - Identify low-confidence claims
  - Note conflicts between sources
  - Append to final-analysis.md
- [ ] Write Recommendations section (if applicable)
  - Synthesize actionable insights
  - Append to final-analysis.md
- [ ] Write Complete Bibliography section
  - Collect all sources from all agents
  - Deduplicate
  - Format consistently
  - Append to final-analysis.md

**Step 3: Final Review**
- [ ] Read complete final-analysis.md
- [ ] Verify all sections are present
- [ ] Check flow and coherence
- [ ] Confirm all agent findings represented
- [ ] Mark synthesis task as completed

**Why Incremental Approach?**
- Prevents token limit errors
- Allows saving progress
- Easier to manage large reports
- Each section can be reviewed before next
- Reduces memory pressure

**Important:** Use Approach A (standard) by default. Only use Approach B (incremental) if you determine the report will be exceptionally long.

## Expected Outputs

After completion, these files should exist:
- ./research-plan.md (already exists)
- ./agents.json (already exists)
- ./assistants/ra-1-*.md
- ./assistants/ra-2-*.md
...
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- ./assistants/ra-v-verification.md")
- ./final-analysis-outline.md (optional - only if using Approach B)
- ./final-analysis.md (required - you create this)

## Research Configuration
- Depth: $RESEARCH_DEPTH
- Word Count per Agent: $WORD_COUNT
- Focus Areas: ${FOCUS_AREAS:-All aspects}
- Verification: $([ "$INCLUDE_VERIFICATION" = "true" ] && echo "Required" || echo "Not required")

## Important Guidelines

### Progress Tracking
- **ALWAYS use TodoWrite** at the start to create tasks for all agents
- Mark tasks as **in_progress** when starting
- Mark tasks as **completed** immediately after finishing
- This helps you and the user track progress

### Agent Communication
- Tell the agent explicitly: "Please execute your research assignment"
- Reference the agent by name: "ra-1-core-technology, please start your research"
- Agents know their assignment from their system prompt
- You don't need to repeat their full assignment to them

### File Management
- Agents save their findings to ./assistants/ra-*-findings.md
- Verify files exist before moving to synthesis
- Read all findings files using the Read tool
- Your synthesis goes to ./final-analysis.md

### Quality Assurance
- Each agent has quality standards embedded in their prompt
- Agents will include citations, confidence markers, and sources
- Your synthesis should preserve this quality metadata
- Note any gaps or conflicts in your final analysis

## Final Completion Checklist

Before finishing, verify:
- [ ] All agent findings files exist in ./assistants/
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- [ ] Verification report exists (ra-v-verification-findings.md)")
- [ ] final-analysis-outline.md exists (only if you used Approach B)
- [ ] final-analysis.md exists and is comprehensive
- [ ] All sections present in final-analysis.md
- [ ] All TodoWrite tasks are marked completed
- [ ] User can see clear completion message

## Ready to Begin?

Start with Phase 1: Setup and Task Assignment.
Create TodoWrite tasks for all agents, then proceed through each phase systematically.

Begin orchestration now!
\`\`\`

## Quality Checklist

Before finishing, verify:
- [ ] research-plan.md is user-friendly and clear
- [ ] agents.json is valid JSON (no syntax errors)
- [ ] orchestration-prompt.md clearly explains the workflow
- [ ] Each agent has unique, non-overlapping focus
- [ ] Agent prompts include quality standards
- [ ] Agent prompts include specific search queries
- [ ] Orchestration prompt lists all agents and their tasks
- [ ] $([ "$INCLUDE_VERIFICATION" = "true" ] && echo "Verification agent can access other agents' outputs" || echo "All agents have clear assignments")

## Important Constraints

1. **DO NOT execute research** - only create the plan and agent definitions
2. **DO NOT use TodoWrite** - this is planning only
3. **DO save three files**: research-plan.md, agents.json, and orchestration-prompt.md
4. **DO make JSON valid** - test it before saving
5. **DO embed quality controls** in every agent prompt

Begin planning now!
PHASE1_EOF

    echo "$prompt_file"
}

# Run Phase 1: Strategic planning with Opus
run_phase1() {
    local feedback="$1"

    if [ -n "$feedback" ]; then
        echo -e "${CYAN}🔄 Refining research strategy based on your feedback...${NC}"
    else
        echo -e "${CYAN}🤔 Creating research strategy with Opus...${NC}"
    fi
    echo -e "${BLUE}   This typically takes 30-60 seconds...${NC}"
    echo

    # Create Phase 1 prompt
    local prompt_file=$(create_phase1_prompt "$feedback")

    # Launch Opus non-interactively with progress indication
    claude --model opus --dangerously-skip-permissions \
         "$(cat "$prompt_file") //ultrathink" > "$OUTPUT_DIR/.phase1-output.log" 2>&1 &
    local claude_pid=$!

    # Show progress while waiting
    local spin='-\|/'
    local i=0
    while kill -0 $claude_pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}   ${spin:$i:1} Planning in progress...${NC}"
        sleep 0.2
    done
    printf "\r${CYAN}   ✓ Planning complete!      ${NC}\n"

    # Check if claude command succeeded
    wait $claude_pid
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo
        echo -e "${RED}❌ Error: Phase 1 planning failed (exit code: $exit_code)${NC}"
        echo -e "${YELLOW}Check log: $OUTPUT_DIR/.phase1-output.log${NC}"
        if [ -f "$OUTPUT_DIR/.phase1-output.log" ]; then
            echo
            echo -e "${BLUE}Last 10 lines of log:${NC}"
            tail -10 "$OUTPUT_DIR/.phase1-output.log"
        fi
        exit 1
    fi

    # Verify required outputs
    if [ ! -f "$OUTPUT_DIR/research-plan.md" ]; then
        echo -e "${RED}❌ Error: research-plan.md not generated${NC}"
        echo -e "${YELLOW}Opus may not have followed instructions. Check log: $OUTPUT_DIR/.phase1-output.log${NC}"
        exit 1
    fi

    if [ ! -f "$OUTPUT_DIR/agents.json" ]; then
        echo -e "${RED}❌ Error: agents.json not generated${NC}"
        echo -e "${YELLOW}Opus may not have followed instructions. Check log: $OUTPUT_DIR/.phase1-output.log${NC}"
        exit 1
    fi

    if [ ! -f "$OUTPUT_DIR/orchestration-prompt.md" ]; then
        echo -e "${RED}❌ Error: orchestration-prompt.md not generated${NC}"
        echo -e "${YELLOW}Opus may not have followed instructions. Check log: $OUTPUT_DIR/.phase1-output.log${NC}"
        exit 1
    fi

    # Verify research-plan.md is not empty
    if [ ! -s "$OUTPUT_DIR/research-plan.md" ]; then
        echo -e "${RED}❌ Error: research-plan.md is empty${NC}"
        exit 1
    fi

    # Verify orchestration-prompt.md is not empty
    if [ ! -s "$OUTPUT_DIR/orchestration-prompt.md" ]; then
        echo -e "${RED}❌ Error: orchestration-prompt.md is empty${NC}"
        exit 1
    fi

    # Validate JSON with detailed error reporting
    if ! python3 -m json.tool "$OUTPUT_DIR/agents.json" > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: agents.json has invalid JSON syntax${NC}"
        echo -e "${YELLOW}JSON validation error:${NC}"
        python3 -m json.tool "$OUTPUT_DIR/agents.json" 2>&1 | head -5
        exit 1
    fi

    # Count agents
    local agent_count=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_DIR/agents.json'))))" 2>/dev/null || echo "unknown")

    echo
    echo -e "${GREEN}✅ Research plan generated successfully!${NC}"
    echo -e "${BLUE}   📊 Agents created: $agent_count${NC}"
    echo -e "${BLUE}   📄 Plan: research-plan.md${NC}"
    echo -e "${BLUE}   🤖 Agents: agents.json${NC}"
    echo -e "${BLUE}   🎯 Orchestration: orchestration-prompt.md${NC}"
    echo
}

# Display research plan to user
display_research_plan() {
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║       Research Strategy Review       ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo

    # Display the research plan with syntax highlighting
    while IFS= read -r line; do
        # Highlight agent assignments (lines starting with ###)
        if [[ "$line" =~ ^###[[:space:]]([0-9]+)\.[[:space:]]RA-([0-9]+):[[:space:]](.+)$ ]]; then
            echo -e "${GREEN}### ${BASH_REMATCH[1]}. ${CYAN}RA-${BASH_REMATCH[2]}:${NC} ${YELLOW}${BASH_REMATCH[3]}${NC}"
        # Highlight section headers (lines starting with ##)
        elif [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
            echo -e "${BLUE}## ${BASH_REMATCH[1]}${NC}"
        # Highlight main title (lines starting with #)
        elif [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
            echo -e "${MAGENTA}# ${BASH_REMATCH[1]}${NC}"
        # Highlight **bold** text
        elif [[ "$line" =~ \*\*([^*]+)\*\* ]]; then
            echo -e "$line" | sed "s/\*\*\([^*]*\)\*\*/${YELLOW}\1${NC}/g"
        else
            echo "$line"
        fi
    done < "$OUTPUT_DIR/research-plan.md"

    echo
    echo -e "${MAGENTA}════════════════════════════════════════${NC}"
    echo
}

# Get user approval with feedback loop
get_user_approval() {
    # Display to stderr so it doesn't get captured by command substitution
    display_research_plan >&2

    echo -e "${BLUE}╭─────────────────────────────────────────╮${NC}" >&2
    echo -e "${BLUE}│  How would you like to proceed?        │${NC}" >&2
    echo -e "${BLUE}╰─────────────────────────────────────────╯${NC}" >&2
    echo >&2
    echo -e "  ${GREEN}✓ [Y/yes/Enter]${NC}  Approve and start research" >&2
    echo -e "  ${RED}✗ [N/no]${NC}         Cancel research" >&2
    echo -e "  ${YELLOW}✎ [text]${NC}         Provide suggestions to refine plan" >&2
    echo >&2
    echo -e "${CYAN}Examples of feedback:${NC}" >&2
    echo -e "  • \"Focus more on costs and risks\"" >&2
    echo -e "  • \"Add an agent for security analysis\"" >&2
    echo -e "  • \"Make it more technical/less technical\"" >&2
    echo >&2
    read -r -p "Your choice: " response </dev/tty

    # Trim whitespace
    response=$(echo "$response" | xargs)

    # Only return the trimmed response (to stdout for capture)
    echo "$response"
}

# Run Phase 2: Execute research with agents
run_phase2() {
    echo
    echo -e "${GREEN}✅ Plan approved!${NC}"
    echo
    echo -e "${CYAN}🚀 Launching specialized research agents...${NC}"
    echo
    echo -e "${YELLOW}Each agent will autonomously research their assigned topic.${NC}"
    echo -e "${YELLOW}This will take approximately $ESTIMATED_TIME.${NC}"
    echo

    # Verify output directory exists
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo -e "${RED}❌ Error: Output directory not found: $OUTPUT_DIR${NC}"
        exit 1
    fi

    # Change to output directory
    cd "$OUTPUT_DIR" || {
        echo -e "${RED}❌ Error: Cannot change to output directory: $OUTPUT_DIR${NC}"
        exit 1
    }

    # Verify agents.json exists and is readable
    if [ ! -f "agents.json" ]; then
        echo -e "${RED}❌ Error: agents.json not found in $OUTPUT_DIR${NC}"
        echo -e "${YELLOW}Phase 1 may not have completed successfully.${NC}"
        exit 1
    fi

    if [ ! -r "agents.json" ]; then
        echo -e "${RED}❌ Error: agents.json is not readable${NC}"
        exit 1
    fi

    # Verify orchestration-prompt.md exists and is readable
    if [ ! -f "orchestration-prompt.md" ]; then
        echo -e "${RED}❌ Error: orchestration-prompt.md not found in $OUTPUT_DIR${NC}"
        echo -e "${YELLOW}Phase 1 may not have completed successfully.${NC}"
        exit 1
    fi

    if [ ! -r "orchestration-prompt.md" ]; then
        echo -e "${RED}❌ Error: orchestration-prompt.md is not readable${NC}"
        exit 1
    fi

    # Count agents for display
    local agent_count=$(python3 -c "import json; print(len(json.load(open('agents.json'))))" 2>/dev/null || echo "multiple")

    # Launch Claude with agents.json and orchestration prompt
    echo -e "${BLUE}Starting interactive research session...${NC}"
    echo -e "${CYAN}Loading $agent_count specialized agents...${NC}"
    echo

    # Launch with both agents and orchestration instructions
    # Use --dangerously-skip-permissions for autonomous research execution
    if ! claude --agents "$(cat agents.json)" --dangerously-skip-permissions "$(cat orchestration-prompt.md)"; then
        echo
        echo -e "${RED}❌ Error: Claude agents execution failed${NC}"
        echo -e "${YELLOW}Check the output above for error details.${NC}"
        exit 1
    fi
}

# Interactive mode function
interactive_mode() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════╗"
    echo "║  Claude Code Heavy v${VERSION} - Interactive  ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Get research question
    echo -e "${GREEN}What would you like to research?${NC}"
    read -r -p "> " query

    # Get research depth
    echo -e "\n${GREEN}Research depth?${NC} (quick/standard/deep, or press Enter for standard)"
    echo -e "${BLUE}  quick:    2-3 assistants, 300-500 words each, ~10 mins${NC}"
    echo -e "${BLUE}  standard: 4-6 assistants, 500-1000 words each, ~20 mins${NC}"
    echo -e "${BLUE}  deep:     6-8 assistants, 1000-2000 words + verification, ~40 mins${NC}"
    read -r -p "> " depth

    if [ -z "$depth" ]; then
        depth="standard"
    fi

    # Validate depth
    if [[ ! "$depth" =~ ^(quick|standard|deep)$ ]]; then
        echo -e "${YELLOW}Invalid depth, using 'standard'${NC}"
        depth="standard"
    fi

    # Get focus areas (optional)
    echo -e "\n${GREEN}Focus areas?${NC} (comma-separated, or press Enter for comprehensive)"
    echo -e "${BLUE}  Example: 'technology,economics,risks' or leave blank for all${NC}"
    read -r -p "> " focus_areas

    # Get output format
    echo -e "\n${GREEN}Output format?${NC} (markdown/text, or press Enter for markdown)"
    read -r -p "> " format

    if [ -z "$format" ]; then
        format="markdown"
    fi

    # Ask about dangerous permissions
    echo -e "\n${YELLOW}Use --dangerously-skip-permissions flag?${NC}"
    echo -e "${RED}Warning: This bypasses security checks. Only use if you trust the research.${NC}"
    echo -e "Enable dangerous mode? (y/N)"
    read -r -p "> " dangerous_mode

    DANGEROUS_MODE="false"
    if [[ "$dangerous_mode" =~ ^[Yy]$ ]]; then
        DANGEROUS_MODE="true"
    fi

    # Confirm settings (default Y)
    echo -e "\n${MAGENTA}═══ Research Configuration ═══${NC}"
    echo -e "  📝 Query: ${CYAN}$query${NC}"
    echo -e "  🎯 Depth: ${CYAN}$depth${NC}"
    if [ -n "$focus_areas" ]; then
        echo -e "  🔍 Focus: ${CYAN}$focus_areas${NC}"
    else
        echo -e "  🔍 Focus: ${CYAN}comprehensive${NC}"
    fi
    echo -e "  📄 Format: ${CYAN}$format${NC}"
    echo -e "  ⚠️  Dangerous mode: ${CYAN}$DANGEROUS_MODE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════${NC}"
    echo -e "\n${GREEN}Proceed? (Y/n)${NC}"
    read -r -p "> " confirm

    # Default to yes if empty or starts with y/Y
    if [[ -z "$confirm" || "$confirm" =~ ^[Yy] ]]; then
        # Continue
        :
    else
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi

    # Set globals for main execution
    QUERY="$query"
    OUTPUT_FORMAT="$format"
    RESEARCH_DEPTH="$depth"
    FOCUS_AREAS="$focus_areas"
}

# Main script starts here
# Check dependencies first
check_dependencies

DANGEROUS_MODE="false"
RESEARCH_DEPTH="standard"
FOCUS_AREAS=""
EXECUTION_PHASE="all"  # all, plan, or research

if [ $# -eq 0 ]; then
    # No arguments - run interactive mode
    interactive_mode
else
    # Command line mode
    QUERY="$1"
    OUTPUT_FORMAT="${2:-markdown}"

    # Parse additional arguments
    shift 2 2>/dev/null || true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dangerous)
                DANGEROUS_MODE="true"
                shift
                ;;
            --depth=*)
                RESEARCH_DEPTH="${1#*=}"
                shift
                ;;
            --focus=*)
                FOCUS_AREAS="${1#*=}"
                shift
                ;;
            *)
                echo -e "${YELLOW}Unknown option: $1${NC}"
                shift
                ;;
        esac
    done

    # Validate depth
    if [[ ! "$RESEARCH_DEPTH" =~ ^(quick|standard|deep)$ ]]; then
        echo -e "${YELLOW}Invalid depth '$RESEARCH_DEPTH', using 'standard'${NC}"
        RESEARCH_DEPTH="standard"
    fi
fi

# Create output directory with descriptive name
FOLDER_NAME=$(generate_folder_name "$QUERY")
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./outputs/${DATE}-${FOLDER_NAME}"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/assistants"

# Set assistant parameters based on depth
case "$RESEARCH_DEPTH" in
    quick)
        MIN_ASSISTANTS=2
        MAX_ASSISTANTS_RECOMMENDED=3
        WORD_COUNT="300-500"
        ESTIMATED_TIME="~10 minutes"
        INCLUDE_VERIFICATION="false"
        ;;
    standard)
        MIN_ASSISTANTS=4
        MAX_ASSISTANTS_RECOMMENDED=6
        WORD_COUNT="500-1000"
        ESTIMATED_TIME="~20 minutes"
        INCLUDE_VERIFICATION="false"
        ;;
    deep)
        MIN_ASSISTANTS=6
        MAX_ASSISTANTS_RECOMMENDED=8
        WORD_COUNT="1000-2000"
        ESTIMATED_TIME="~40 minutes"
        INCLUDE_VERIFICATION="true"
        ;;
esac

# Banner
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════╗"
echo "║   Claude Code Heavy v${VERSION} Research      ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${MAGENTA}═══ Configuration ═══${NC}"
echo -e "  ${YELLOW}Query:${NC} $QUERY"
echo -e "  ${YELLOW}Depth:${NC} $RESEARCH_DEPTH ($ESTIMATED_TIME)"
echo -e "  ${YELLOW}Assistants:${NC} $MIN_ASSISTANTS-$MAX_ASSISTANTS_RECOMMENDED recommended"
echo -e "  ${YELLOW}Word Count:${NC} $WORD_COUNT per assistant"
if [ -n "$FOCUS_AREAS" ]; then
    echo -e "  ${YELLOW}Focus:${NC} $FOCUS_AREAS"
fi
echo -e "  ${YELLOW}Output:${NC} $OUTPUT_DIR"
echo -e "${MAGENTA}══════════════════════${NC}"
echo

# Create the orchestration prompt
if [ "$OUTPUT_FORMAT" = "markdown" ]; then
    PROMPT_FILE="$OUTPUT_DIR/orchestration-prompt.md"
    EXT="md"

    # Build focus areas section if provided
    FOCUS_SECTION=""
    if [ -n "$FOCUS_AREAS" ]; then
        FOCUS_SECTION="
**Focus Areas**: $FOCUS_AREAS
Your research should prioritize these areas while maintaining comprehensive coverage."
    fi

    # Build verification section for deep research
    VERIFICATION_SECTION=""
    if [ "$INCLUDE_VERIFICATION" = "true" ]; then
        VERIFICATION_SECTION="
3. **Verification Phase** (REQUIRED for deep research):
   - Assign RA-V (Verification Assistant) to cross-check key claims
   - Identify contradictions between assistants' findings
   - Flag claims with single-source support vs multi-source verification
   - Check for bias or missing perspectives
   - Create verification report: \`$OUTPUT_DIR/assistants/ra-verification.md\`"
    fi

    # Set model recommendations based on depth
    case "$RESEARCH_DEPTH" in
        quick)
            MODEL_RECOMMENDATION="**Recommended Model**: Haiku for all phases (fast, cost-effective)
**Rationale**: Quick research prioritizes speed over maximum depth"
            ;;
        standard)
            MODEL_RECOMMENDATION="**Recommended Model**: Sonnet for all phases (balanced)
**Rationale**: Standard research balances quality and performance"
            ;;
        deep)
            MODEL_RECOMMENDATION="**Recommended Models**:
- **Planning Phase**: Opus (superior strategic thinking)
- **Research Phase**: Sonnet (balanced performance)
- **Verification Phase**: Opus (critical analysis)
**Rationale**: Deep research uses optimal model for each phase"
            ;;
    esac

    cat > "$PROMPT_FILE" << EOF
# Claude Code Heavy v${VERSION} - Enhanced Research Orchestration

You are orchestrating a multi-agent research system with quality controls and verification. You have full autonomy over the research process.

## Research Configuration

**Query**: $QUERY

**Research Depth**: $RESEARCH_DEPTH
- Recommended Assistants: $MIN_ASSISTANTS-$MAX_ASSISTANTS_RECOMMENDED
- Target Word Count: $WORD_COUNT per assistant
- Estimated Duration: $ESTIMATED_TIME
- Verification Required: $INCLUDE_VERIFICATION
$FOCUS_SECTION

**Output Directory**: \`$OUTPUT_DIR\`

$MODEL_RECOMMENDATION

---

## Research Methodology & Quality Standards

### Source Quality Requirements
- **Diversity**: Use 3-5 different sources per major claim
- **Recency**: Prioritize 2024-2025 data; explicitly note older information
- **Authority**: Prefer primary sources, peer-reviewed research, official documentation
- **Triangulation**: Cross-verify important facts across independent sources

### Citation Standards (MANDATORY)
Every assistant MUST include:
1. **Inline URLs**: \`[descriptive text](https://source-url)\` for each claim
2. **Confidence Indicators**:
   - 🟢 **HIGH**: Multiple independent sources confirm, recent data
   - 🟡 **MEDIUM**: Single authoritative source, or older but reliable data
   - 🔴 **LOW**: Limited sources, uncertain, or extrapolated information
3. **Temporal Markers**: "As of [Month Year]" for time-sensitive claims
4. **Sources List**: Bibliography at end of each assistant's findings

**Citation Examples** (follow this pattern):
\`\`\`markdown
✅ GOOD: "PostgreSQL achieves 95% ACID compliance 🟢 ([Official PostgreSQL Docs](https://postgresql.org/docs/acid), accessed Nov 2025)"

✅ GOOD: "Migration costs range from \\\$50k-\\\$200k 🟡 ([AWS Migration Case Study](https://aws.amazon.com/case-study), 2024)"

❌ BAD: "PostgreSQL is better than MySQL" (no source, no confidence, vague)

❌ BAD: "According to experts, performance improves" (no specific source URL)
\`\`\`

### Quality Control Checklist
- [ ] Each major claim has source URL
- [ ] Confidence level marked for key findings
- [ ] Contradictory information acknowledged
- [ ] Gaps in available research identified
- [ ] Potential biases noted

---

## Meta-Research & Strategic Thinking

### Before Starting Research - Ask Yourself:
1. **What's NOT obvious?** Look beyond surface-level answers
2. **Who benefits?** Consider potential biases in sources
3. **What's missing?** Identify perspectives not commonly represented
4. **What could go wrong?** Consider failure modes and risks
5. **What are the trade-offs?** Nothing is universally better

### During Research - Adaptive Strategies:
**If initial searches yield poor results:**
- Try alternative terminology (e.g., "container orchestration" vs "Kubernetes")
- Broaden scope (e.g., "database migration" instead of specific DB names)
- Look for adjacent topics (e.g., if direct comparison lacking, research each separately)
- Search for case studies, not just technical docs

**If sources conflict:**
- Note the conflict explicitly 🔴
- Investigate source authority and recency
- Look for meta-analyses or systematic reviews
- Consider context: different use cases may have different answers

**If confidence is low across the board:**
- Acknowledge this prominently in findings
- Explain WHY information is scarce
- Recommend additional research areas
- Provide conditional guidance: "IF X, THEN Y"

### Research Depth Calibration:
**Signs you should go deeper:**
- Query involves critical business decision (\\\$100k+ impact)
- High stakeholder sensitivity (security, compliance, ethics)
- Sources contradict each other significantly
- Initial findings reveal unexpected complexity

**Signs you can stay surface-level:**
- Query is for general understanding
- Topic well-established with consensus
- Time/budget constrained
- Preliminary scoping before deep dive

---

## Research Process

### 1. Planning Phase
**Task**: Create high-level research strategy
- Analyze the query complexity and scope
- Determine optimal number of assistants ($MIN_ASSISTANTS-$MAX_ASSISTANTS_RECOMMENDED recommended)
- Assign specific roles and focused research questions to each
- Consider diverse perspectives (technical, economic, social, ethical, etc.)
- **Output**: Save detailed plan to \`$OUTPUT_DIR/research-plan.md\`

**Research Plan Must Include**:
- Number of assistants and rationale
- Each assistant's role and specific questions
- Expected coverage areas
- Potential knowledge gaps to address

### 2. Agent Declaration Phase (CRITICAL)
**Task**: Define specialized subagents with custom capabilities

Now that you understand the research direction, create **actual Claude Code subagents** for each research assistant. This leverages Claude Code's native agent orchestration for better specialization and isolation.

**Why This Matters**:
- Each agent gets a **custom system prompt** tailored to their expertise
- Agents operate with **full tool access** (WebSearch, Read, Write, etc.)
- Better **cognitive specialization** than role-playing
- **Parallel execution** with proper isolation
- **Reproducible** research with defined agent capabilities

**Create**: \`$OUTPUT_DIR/agents.json\` with this structure:

\`\`\`json
{
  "ra-1-[role-slug]": {
    "description": "[One-line description of what this agent researches]",
    "prompt": "[Custom system prompt - see template below]"
  },
  "ra-2-[role-slug]": {
    "description": "[One-line description]",
    "prompt": "[Custom system prompt]"
  }
  // ... up to ra-N agents
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo '  ,
  "ra-v-verification": {
    "description": "Cross-verifies findings from all research assistants",
    "prompt": "[Verification-specific system prompt]"
  }')
}
\`\`\`

**Agent System Prompt Template**:
\`\`\`
You are [ROLE], a specialized research assistant for the query: "$QUERY"

## Your Specific Responsibility
[Detailed description of what this agent researches]

## Your Expertise
- [Domain knowledge area 1]
- [Domain knowledge area 2]
- [Domain knowledge area 3]

## Research Question
[The specific focused question this agent must answer]

## Quality Standards (MANDATORY)
- **Citations**: Include [source URL] for EVERY claim
- **Confidence**: Mark findings with 🟢 HIGH, 🟡 MEDIUM, 🔴 LOW
- **Sources**: Use 3-5 different sources per major claim
- **Recency**: Prioritize 2024-2025 data, note older info
- **Gaps**: Explicitly acknowledge what you couldn't find

## Output Requirements
Save your findings to: \`$OUTPUT_DIR/assistants/ra-N-findings.md\`

Structure:
# Research Assistant N: [Your Role]

## Assignment
[Your specific research question]

## Key Findings
[Main discoveries with 🟢🟡🔴 confidence indicators]

## Detailed Analysis
[$WORD_COUNT words with inline source citations]

## Confidence Assessment
- High confidence claims: X
- Medium confidence claims: Y
- Low confidence claims: Z

## Gaps & Limitations
[What you couldn't find or verify]

## Sources
1. [Title](URL) - Accessed [Date]
2. [Title](URL) - Accessed [Date]

## Search Strategy
Start with parallel WebSearch tool calls for efficiency:
- [Suggested search query 1]
- [Suggested search query 2]
- [Suggested search query 3]

If searches yield poor results, adapt:
- Try alternative terminology
- Broaden or narrow scope
- Look for adjacent topics or case studies

Focus: $([ -n "$FOCUS_AREAS" ] && echo "$FOCUS_AREAS" || echo "comprehensive coverage")
\`\`\`

**Example Agent Definition**:
\`\`\`json
{
  "ra-1-architecture-expert": {
    "description": "Analyzes PostgreSQL vs MongoDB architectural differences and trade-offs",
    "prompt": "You are an Architecture Expert specializing in database systems.\\n\\nYour specific responsibility: Analyze the fundamental architectural differences between PostgreSQL (relational, ACID) and MongoDB (document, eventual consistency). Focus on: data models, transaction handling, scaling approaches, and when each architecture excels.\\n\\nExpertise: Distributed systems, database internals, ACID vs BASE, CAP theorem\\n\\nResearch Question: What are the core architectural differences and what are the practical implications for application design?\\n\\n[... include full quality standards and output requirements ...]"
  }
}
\`\`\`

**Best Practices for Agent Prompts**:
1. **Be Specific**: Define exactly what domain/question this agent covers
2. **Set Context**: Include the main query and how this agent contributes
3. **Define Expertise**: What knowledge domains should this agent draw from
4. **Provide Strategy**: Suggest initial search queries
5. **Set Constraints**: Word count, focus areas, confidence requirements
6. **Enable Adaptation**: Include guidance for handling research challenges

**After Creating agents.json**:
- Validate JSON syntax
- Ensure each agent has clear, non-overlapping responsibilities
- Verify system prompts include quality standards
- Check that verification agent (if included) can access all other agents' outputs

**Next Step**: The agents.json will be used to launch actual Claude Code subagents for parallel research execution.

---

### 3. Research Phase
**Task**: Execute research using specialized subagents

**Option A - Using Claude Code Native Agents** (RECOMMENDED):
\`\`\`bash
# Launch research with your defined agents
claude --agents \$(cat $OUTPUT_DIR/agents.json)

# Each agent will autonomously:
# - Execute their research with their custom system prompt
# - Use parallel WebSearch calls for efficiency
# - Follow their specific quality standards
# - Save findings to their designated output file
\`\`\`

**Option B - Manual Orchestration** (if agents not supported):
- Manually role-play each assistant
- Research their assigned question following agent's system prompt
- Use parallel WebSearch tool calls for efficiency
- Save findings to: \`$OUTPUT_DIR/assistants/ra-N-findings.md\`

**Agent Execution Notes**:
- Agents defined in agents.json have full tool access
- Each agent operates with specialized knowledge and focus
- Agents can work in parallel for faster research
- Quality standards are embedded in each agent's system prompt

**Each Assistant's Report Must Include**:
\`\`\`markdown
# Research Assistant N: [Role Title]

## Assignment
[Specific research question]

## Key Findings
[Main discoveries with 🟢🟡🔴 confidence indicators]

## Detailed Analysis
[$WORD_COUNT words with inline source citations]

## Confidence Assessment
- High confidence claims: X
- Medium confidence claims: Y
- Low confidence claims: Z

## Gaps & Limitations
[What couldn't be found or verified]

## Sources
1. [Source Title](URL) - Accessed [Date]
2. [Source Title](URL) - Accessed [Date]
...
\`\`\`
$VERIFICATION_SECTION

### $([ "$INCLUDE_VERIFICATION" = "true" ] && echo "4" || echo "3"). Synthesis Phase
**Task**: Integrate all findings into comprehensive analysis
- Review ALL assistant findings and verification report
- Synthesize into coherent narrative
- Integrate confidence levels throughout
- Attribute insights to specific assistants
- **Output**: Save to \`$OUTPUT_DIR/final-analysis.md\`

**Final Analysis Must Include**:
\`\`\`markdown
# [Query Title]: Comprehensive Analysis

## Executive Summary
[2-3 paragraph overview of key findings]

## Research Methodology
- Assistants deployed: [N]
- Total sources reviewed: [~X]
- Research duration: [X minutes]
- Confidence distribution: 🟢X% 🟡Y% 🔴Z%

## Detailed Findings
[Organized by themes, properly attributed to assistants]
- Citations throughout: (Source: RA-N, [Title](URL))
- Confidence markers: 🟢🟡🔴

## Cross-Cutting Insights
[Synthesis across multiple assistant findings]

## Limitations & Gaps
[Identified weaknesses in available research]

## Areas of Uncertainty
[Claims marked 🔴 or conflicting information]

## Recommendations
[Actionable insights from research]

## Complete Bibliography
[All sources from all assistants, deduplicated]
\`\`\`

---

## Task Management

**IMPORTANT**: Use the **TodoWrite** tool to track research progress:

1. After creating research plan, add todos for each phase
2. **After declaring agents**, mark Agent Declaration as complete
3. Mark each assistant's research as in_progress when starting
4. Mark completed immediately after finishing each assistant
5. Track verification phase (if applicable)
6. Track synthesis phase

Example:
\`\`\`
- [ ] Create research plan
- [ ] Declare specialized agents (agents.json)
- [ ] RA-1: [Role] research
- [ ] RA-2: [Role] research
- [ ] RA-3: [Role] research
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- [ ] RA-V: Verification & cross-checking")
- [ ] Final synthesis and analysis
\`\`\`

**Agent Declaration Benefits**:
- Each research assistant becomes a **real Claude Code subagent**
- Custom system prompts ensure **specialized expertise**
- Better **isolation** and **parallel execution**
- **Reproducible** research with defined capabilities
- Agents can reference each other's outputs during verification

---

## Common Research Templates

These templates provide starting points - adapt based on query specifics.

### 1. Comparative Analysis (e.g., "X vs Y", "A vs B comparison")
**Best for**: Technology choices, vendor selection, methodology comparison

**Suggested assistants** (4-6):
- RA-1: X Architecture & Core Technology
- RA-2: Y Architecture & Core Technology
- RA-3: Performance & Benchmarking (focus on objective metrics)
- RA-4: Features & Capabilities (feature parity analysis)
- RA-5: Market Adoption & Use Cases (who uses what, why)
- RA-6: Developer Experience & Ecosystem (community, docs, tooling)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Verify benchmark claims, check for vendor bias")

**Critical questions to address**:
- What are the non-obvious trade-offs?
- When would you choose X over Y (and vice versa)?
- What are the total costs of ownership?
- What are the migration/switching costs?

### 2. Impact Analysis (e.g., "How will X impact Y?")
**Best for**: Technology adoption, policy changes, market shifts

**Suggested assistants** (5-6):
- RA-1: Current State & Direct Effects (baseline + immediate impact)
- RA-2: Economic & Market Impact (costs, benefits, market dynamics)
- RA-3: Technical Implementation (how to implement, technical challenges)
- RA-4: Social & Ethical Implications (stakeholders, equity, unintended consequences)
- RA-5: Regulatory & Policy Considerations (compliance, legal, governance)
- RA-6: Future Outlook & Predictions (2-5 year horizon, scenarios)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Fact-check statistics, validate expert predictions")

**Critical questions to address**:
- Who wins and who loses?
- What are second-order effects?
- What could prevent this impact from occurring?
- What are alternative scenarios?

### 3. Market/Location Analysis (e.g., "5-year outlook for X")
**Best for**: Investment decisions, market entry, strategic planning

**Suggested assistants** (6):
- RA-1: Economic & Business Climate (GDP, investment, macro trends)
- RA-2: Technology & Innovation (emerging tech, R&D, startups)
- RA-3: Demographics & Social Trends (population, culture, values)
- RA-4: Infrastructure & Development (physical, digital, institutional)
- RA-5: Market Dynamics & Competition (players, barriers, opportunities)
- RA-6: Risks & Challenges (threats, uncertainties, failure modes)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Cross-verify economic data, validate growth projections")

**Critical questions to address**:
- What are the base case, bull case, and bear case scenarios?
- What are the key uncertainty factors?
- What leading indicators should we monitor?

### 4. Technical Deep Dive (e.g., "How does X work?", "Explain Y technology")
**Best for**: Learning, architecture reviews, technical due diligence

**Suggested assistants** (3-5):
- RA-1: Core Concepts & Fundamentals (foundational understanding)
- RA-2: Architecture & Implementation (how it's built, design patterns)
- RA-3: Use Cases & Applications (real-world examples, when to use)
- RA-4: Alternatives & Trade-offs (competing approaches, pros/cons)
- RA-5: Practical Guidance (getting started, best practices, pitfalls)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Verify technical accuracy, check for oversimplifications")

**Critical questions to address**:
- What problem does this solve that alternatives don't?
- What are the fundamental constraints/limitations?
- What should I NOT use this for?

### 5. Decision Support (e.g., "Should we do X?", "Evaluate Y decision")
**Best for**: Business decisions, strategic choices, go/no-go decisions

**Suggested assistants** (5-6):
- RA-1: Current State Analysis (where we are, baseline)
- RA-2: Benefits & Opportunities (upside case, what we gain)
- RA-3: Costs & Risks (downside case, what we lose/risk)
- RA-4: Alternatives & Options (other paths, opportunity cost)
- RA-5: Implementation & Execution (how to do it, timeline, resources)
- RA-6: Decision Framework (criteria, trade-offs, recommendation)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Validate cost estimates, check risk assumptions")

**Critical questions to address**:
- What's the reversibility of this decision?
- What information would change our answer?
- What's the "do nothing" scenario?
- What's the minimal viable approach?

### 6. Trend Analysis (e.g., "Latest trends in X", "What's next for Y?")
**Best for**: Innovation tracking, competitive intelligence, strategic foresight

**Suggested assistants** (4-5):
- RA-1: Emerging Trends & Innovations (what's new, early signals)
- RA-2: Market Drivers & Forces (why these trends, underlying causes)
- RA-3: Key Players & Ecosystem (who's leading, who's investing)
- RA-4: Adoption & Maturity (how fast, what's proven vs hype)
- RA-5: Future Outlook (where is this going, what's next)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Separate hype from reality, validate trend data")

**Critical questions to address**:
- Which trends have staying power vs fads?
- What's being overhyped/underhyped?
- What are the contrarian views?

### 7. Problem-Solution Exploration (e.g., "How to solve X?", "Best way to achieve Y?")
**Best for**: Problem-solving, solution design, approach selection

**Suggested assistants** (4-6):
- RA-1: Problem Definition & Context (root causes, constraints, requirements)
- RA-2: Existing Solutions & Approaches (what others have done)
- RA-3: Novel/Emerging Solutions (cutting-edge, innovative approaches)
- RA-4: Comparative Evaluation (pros/cons, suitability for context)
- RA-5: Implementation Roadmap (phased approach, quick wins vs long-term)
- RA-6: Risks & Failure Modes (what could go wrong, mitigation)
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- RA-V: Validate solution claims, check for missing approaches")

**Critical questions to address**:
- Are we solving the right problem?
- What are unconventional solutions?
- What's the 80/20 approach?

---

## Adaptive Template Selection

**Don't force-fit queries into templates.** Consider:
- Query complexity and scope
- Available information (some topics have little data)
- Stakeholder needs (what decision are they making?)
- Time constraints (can always do follow-up deep dive)

**Mix and match** template elements as needed. Real queries often span multiple templates.

---

## Critical Thinking Guidelines

**Avoid These Pitfalls**:
- ❌ Single-source claims without verification
- ❌ Presenting marketing claims as facts
- ❌ Ignoring contradictory evidence
- ❌ Overconfidence on limited data
- ❌ Failing to note information currency

**Best Practices**:
- ✅ Acknowledge uncertainty explicitly
- ✅ Note when sources conflict
- ✅ Distinguish facts from projections
- ✅ Consider multiple perspectives
- ✅ Identify potential biases

---

## Output File Structure

\`\`\`
$OUTPUT_DIR/
├── orchestration-prompt.md       # This prompt
├── research-plan.md              # Your research strategy
├── assistants/
│   ├── ra-1-findings.md          # Assistant 1 research
│   ├── ra-2-findings.md          # Assistant 2 research
│   ├── ra-N-findings.md          # Additional assistants
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "│   └── ra-verification.md       # Verification report")
├── final-analysis.md             # Synthesized analysis
└── metadata.json                 # Research metadata (optional)
\`\`\`

---

## Start Your Research

**Next Steps**:
1. Use TodoWrite to create task list
2. Analyze the query and create research plan
3. **Declare specialized agents** (create agents.json with custom system prompts)
4. Execute research using subagents with quality controls
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "5. Run verification phase")
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "6. Synthesize findings" || echo "5. Synthesize findings")

**Key Innovation**: The **Agent Declaration phase** transforms research assistants from role-playing into actual Claude Code subagents with specialized capabilities. This provides:
- **Better specialization** through custom system prompts
- **True parallel execution** with proper isolation
- **Reproducible research** with defined agent behaviors
- **Enhanced quality** through embedded standards in each agent

Remember: **Quality over speed**. Thorough, well-cited research is more valuable than quick, unsupported claims.

**Begin now by creating your research plan!** 🚀
EOF
else
    # Text format (simplified version)
    PROMPT_FILE="$OUTPUT_DIR/orchestration-prompt.txt"
    EXT="txt"
    cat > "$PROMPT_FILE" << EOF
=== Claude Code Heavy v${VERSION} - Research Orchestration ===

QUERY: $QUERY
DEPTH: $RESEARCH_DEPTH ($ESTIMATED_TIME)
ASSISTANTS: $MIN_ASSISTANTS-$MAX_ASSISTANTS_RECOMMENDED recommended
WORD COUNT: $WORD_COUNT per assistant
VERIFICATION: $INCLUDE_VERIFICATION
$([ -n "$FOCUS_AREAS" ] && echo "FOCUS: $FOCUS_AREAS")
OUTPUT: $OUTPUT_DIR

--- QUALITY STANDARDS (MANDATORY) ---

1. CITATIONS: Include [source URLs] for all claims
2. CONFIDENCE: Mark claims with confidence levels (HIGH/MEDIUM/LOW)
3. SOURCES: 3-5 different sources per major claim
4. RECENCY: Prioritize 2024-2025 data, note older info
5. VERIFICATION: Cross-check important facts

--- RESEARCH PROCESS ---

1. PLANNING ($OUTPUT_DIR/research-plan.md)
   - Determine number of assistants needed
   - Assign roles and specific questions
   - Identify coverage areas

2. AGENT DECLARATION ($OUTPUT_DIR/agents.json) ***CRITICAL***
   - Create Claude Code subagent definitions
   - Each agent gets custom system prompt
   - Define agent expertise and responsibilities
   - Set quality standards per agent
   - Enable parallel execution with proper isolation

   Format: {"agent-name": {"description": "...", "prompt": "..."}}

   Launch agents with: claude --agents \$(cat $OUTPUT_DIR/agents.json)

3. RESEARCH ($OUTPUT_DIR/assistants/ra-N-findings.md)
   - Agents execute autonomously with custom prompts
   - Use parallel web searches
   - Include inline source URLs
   - Mark confidence levels
   - Note gaps and limitations
   - Add bibliography

$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "4. VERIFICATION ($OUTPUT_DIR/assistants/ra-verification.md)
   - Cross-check key claims
   - Identify contradictions
   - Flag single-source claims
")
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "5" || echo "4"). SYNTHESIS ($OUTPUT_DIR/final-analysis.md)
   - Executive summary
   - Research methodology section
   - Confidence distribution
   - Complete bibliography
   - Limitations and gaps

--- TASK MANAGEMENT ---

Use TodoWrite tool to track progress:
- Create research plan
- Declare specialized agents (agents.json)
- Each assistant's research
$([ "$INCLUDE_VERIFICATION" = "true" ] && echo "- Verification phase")
- Final synthesis

--- START YOUR RESEARCH ---

Begin by creating your research plan with TodoWrite task tracking!
EOF
fi

# Execute Two-Phase Research
# Phase 1: Strategic planning (automatic, transparent to user)
# Phase 2: Research execution (with agents, user approved)

run_phase1 ""

# User approval loop with feedback
while true; do
    response=$(get_user_approval)

    # Normalize to lowercase for comparison
    response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    # Check for approval (empty, y, yes, ok, approve)
    if [[ -z "$response" || "$response_lower" =~ ^(y|yes|ok|approve)$ ]]; then
        # Approved - proceed to Phase 2
        echo
        echo -e "${GREEN}✅ Starting research with approved plan...${NC}"
        echo
        run_phase2
        break

    # Check for cancel (n, no, cancel, quit, exit)
    elif [[ "$response_lower" =~ ^(n|no|cancel|quit|exit)$ ]]; then
        # Confirm cancellation
        echo
        echo -e "${YELLOW}⚠️  Are you sure you want to cancel? (y/n)${NC}"
        read -r -p "Confirm: " confirm
        confirm_lower=$(echo "$confirm" | tr '[:upper:]' '[:lower:]' | xargs)

        if [[ "$confirm_lower" =~ ^(y|yes)$ ]]; then
            echo
            echo -e "${RED}❌ Research cancelled.${NC}"
            exit 0
        else
            echo
            echo -e "${CYAN}↻ Returning to plan review...${NC}"
            echo
            continue
        fi

    # Feedback provided
    else
        # Validate feedback is not just whitespace
        if [[ -z "$response" ]]; then
            echo
            echo -e "${YELLOW}⚠️  Empty feedback provided. Please enter your suggestions or press Enter to approve.${NC}"
            echo
            continue
        fi

        # Show captured feedback
        echo
        echo -e "${CYAN}📝 Feedback received:${NC}"
        echo -e "${YELLOW}   \"$response\"${NC}"
        echo

        # Re-run Phase 1 with feedback
        run_phase1 "$response"
    fi
done

# Phase 2 completed
echo
echo -e "${GREEN}✅ Research completed!${NC}"
echo
echo -e "${MAGENTA}═══ Research Outputs ═══${NC}"
echo -e "  ${YELLOW}Directory:${NC} $OUTPUT_DIR/"
echo -e "  ${YELLOW}Plan:${NC} research-plan.md"
echo -e "  ${YELLOW}Agents:${NC} agents.json"
echo -e "  ${YELLOW}Findings:${NC} assistants/ra-*-findings.md"
if [ "$INCLUDE_VERIFICATION" = "true" ]; then
    echo -e "  ${YELLOW}Verification:${NC} assistants/ra-verification.md"
fi
echo -e "  ${YELLOW}Synthesis:${NC} final-analysis.md"
echo -e "${MAGENTA}═══════════════════════${NC}"
echo
