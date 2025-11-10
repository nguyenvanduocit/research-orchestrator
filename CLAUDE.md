# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Claude Code Heavy v2.0** is an enhanced multi-agent research orchestration system with quality controls, verification, and flexible depth settings. The system enables Claude to autonomously conduct rigorous, well-cited research with confidence scoring and cross-verification capabilities.

### What's New in v2.0
- **Quality Controls**: Mandatory citations, confidence scoring (🟢🟡🔴), source verification
- **Research Depth**: Three modes (quick/standard/deep) with automatic configuration
- **Verification Phase**: Deep mode includes cross-checking and contradiction detection
- **Focus Areas**: Optional targeting of specific research dimensions
- **Simplified Architecture**: Removed git worktrees complexity - uses role-playing instead
- **Enhanced Prompts**: Comprehensive research methodology guidelines
- **Task Tracking**: Integration with TodoWrite for progress visibility

## Key Architecture Concepts

### Research Orchestration Model
The system uses **role-based research assistants** (RA-1 through RA-N) that Claude orchestrates:
- Each assistant has a specific role (e.g., "Architecture Expert", "Performance Analyst")
- Assistants conduct focused research on assigned questions
- All research includes mandatory citations and confidence scoring
- Optional verification assistant (RA-V) cross-checks findings in deep mode

### Research Depth Modes

**Quick Mode** (~10 minutes):
- 2-3 assistants
- 300-500 words per assistant
- No verification phase
- Best for: Quick overviews, initial scoping

**Standard Mode** (~20 minutes, default):
- 4-6 assistants
- 500-1000 words per assistant
- No verification phase
- Best for: Comprehensive research, most queries

**Deep Mode** (~40 minutes):
- 6-8 assistants
- 1000-2000 words per assistant
- **Verification phase required**
- Best for: Critical decisions, high-stakes analysis

### Quality Control Framework

**Mandatory Requirements**:
1. **Citations**: Every claim must link to source URL
2. **Confidence Markers**:
   - 🟢 HIGH: Multiple independent sources, recent data
   - 🟡 MEDIUM: Single authoritative source, older but reliable
   - 🔴 LOW: Limited sources, uncertain, extrapolated
3. **Source Diversity**: 3-5 sources per major claim
4. **Recency**: Prioritize 2024-2025 data, mark older information
5. **Verification**: Cross-check important facts (automatic in deep mode)

### Output Structure
```
outputs/[date]-[query-slug]/
├── orchestration-prompt.md    # Enhanced orchestration prompt
├── research-plan.md          # Research strategy & assistant assignments
├── assistants/
│   ├── ra-1-findings.md      # Assistant 1 research (with citations)
│   ├── ra-2-findings.md      # Assistant 2 research
│   ├── ra-N-findings.md      # Additional assistants
│   └── ra-verification.md    # Verification report (deep mode only)
└── final-analysis.md         # Synthesized comprehensive analysis
```

## Running the System

### Interactive Mode (Recommended)
```bash
./ccheavy.sh
```

You'll be prompted for:
1. **Research query**: What you want to research
2. **Depth**: quick/standard/deep
3. **Focus areas**: Optional comma-separated (e.g., "technology,economics,risks")
4. **Output format**: markdown (default) or text
5. **Dangerous mode**: Security flag (default: off)

### Command Line Mode
```bash
# Basic usage (standard depth)
./ccheavy.sh "research query"

# With depth control
./ccheavy.sh "research query" markdown --depth=deep

# With focus areas
./ccheavy.sh "research query" markdown --depth=standard --focus=technology,economics

# All options
./ccheavy.sh "research query" markdown --depth=deep --focus=risks,ethics --dangerous
```

### Command Line Options
- `--depth=quick|standard|deep` - Research depth (default: standard)
- `--focus=area1,area2,...` - Focus areas (optional)
- `--dangerous` - Skip permission checks (use with caution)

## Development Commands

**Note**: This is a bash-based orchestration system with no build process, tests, or linting.

### Common Operations
```bash
# Check output structure
ls -R outputs/

# Delete all outputs
rm -rf outputs/*

# View recent research
ls -lt outputs/ | head

# Check script version
grep "VERSION=" ccheavy.sh
```

## When Operating as Research Orchestrator

When `ccheavy.sh` launches Claude with the orchestration prompt, you should follow this enhanced workflow:

### 1. Planning Phase
**Use TodoWrite immediately** to create task list:
```markdown
- [ ] Create research plan
- [ ] RA-1: [Role] research
- [ ] RA-2: [Role] research
- [ ] RA-N: [Role] research
- [ ] RA-V: Verification (if deep mode)
- [ ] Final synthesis
```

**Analyze the query**:
- Determine optimal number of assistants (respect depth recommendations)
- Assign specific roles and focused questions
- Consider diverse perspectives (technical, economic, social, ethical, etc.)

**Save plan to**: `$OUTPUT_DIR/research-plan.md`

### 2. Research Phase
Each assistant must:

**Follow Quality Standards**:
- Include inline source URLs for all claims: `[text](https://url)`
- Mark confidence levels: 🟢 HIGH 🟡 MEDIUM 🔴 LOW
- Use 3-5 different sources per major claim
- Note information date: "As of [Month Year]"
- Identify gaps and limitations

**Report Structure**:
```markdown
# Research Assistant N: [Role Title]

## Assignment
[Specific research question]

## Key Findings
[Main discoveries with 🟢🟡🔴 confidence indicators]

## Detailed Analysis
[Required word count with inline source citations]

## Confidence Assessment
- High confidence claims: X
- Medium confidence claims: Y
- Low confidence claims: Z

## Gaps & Limitations
[What couldn't be found or verified]

## Sources
1. [Source Title](URL) - Accessed [Date]
2. [Source Title](URL) - Accessed [Date]
```

**Save to**: `$OUTPUT_DIR/assistants/ra-N-findings.md`

**Update TodoWrite**: Mark each assistant completed immediately after finishing

### 3. Verification Phase (Deep Mode Only)
**Required for `--depth=deep`**:
- Assign RA-V (Verification Assistant)
- Cross-check key claims from all assistants
- Identify contradictions between sources
- Flag single-source claims vs multi-source verification
- Check for bias or missing perspectives
- **Save to**: `$OUTPUT_DIR/assistants/ra-verification.md`

### 4. Synthesis Phase
**Final analysis must include**:

```markdown
# [Query Title]: Comprehensive Analysis

## Executive Summary
[2-3 paragraphs of key findings]

## Research Methodology
- Assistants deployed: [N]
- Total sources reviewed: [~X]
- Research duration: [X minutes]
- Confidence distribution: 🟢X% 🟡Y% 🔴Z%

## Detailed Findings
[Organized by themes]
- Properly attributed: (Source: RA-N, [Title](URL))
- Confidence markers throughout: 🟢🟡🔴

## Cross-Cutting Insights
[Synthesis across assistants]

## Limitations & Gaps
[Identified weaknesses]

## Areas of Uncertainty
[Claims marked 🔴 or conflicts]

## Recommendations
[Actionable insights]

## Complete Bibliography
[All sources, deduplicated]
```

**Save to**: `$OUTPUT_DIR/final-analysis.md`

## Research Quality Standards

### What Makes Excellent Research

**✅ Best Practices**:
- 3-5 independent sources per major claim
- Explicit confidence levels on all key findings
- Acknowledge uncertainty and conflicts
- Distinguish facts from projections
- Consider multiple perspectives
- Note information currency
- Identify potential biases

**❌ Avoid These Pitfalls**:
- Single-source claims without verification
- Presenting marketing claims as facts
- Ignoring contradictory evidence
- Overconfidence on limited data
- Failing to note information age
- No source citations
- Missing perspective diversity

### Research Templates

The orchestration prompt includes templates for common query types:

**Comparative Analysis** (e.g., "X vs Y"):
- RA-1: X Architecture
- RA-2: Y Architecture
- RA-3: Performance
- RA-4: Features
- RA-5: Market Adoption
- RA-6: Developer Experience
- RA-V: Verify benchmarks (deep mode)

**Impact Analysis** (e.g., "How will X impact Y?"):
- RA-1: Current State & Direct Effects
- RA-2: Economic Impact
- RA-3: Technical Implementation
- RA-4: Social & Ethical Implications
- RA-5: Regulatory Considerations
- RA-6: Future Outlook
- RA-V: Fact-check statistics (deep mode)

**Market/Location Analysis** (e.g., "5-year outlook"):
- RA-1: Economic Climate
- RA-2: Technology & Innovation
- RA-3: Demographics
- RA-4: Infrastructure
- RA-5: Market Dynamics
- RA-6: Risks & Challenges
- RA-V: Cross-verify data (deep mode)

## Important Guidelines

### Parallel Execution
- **Use parallel WebSearch tool calls** to maximize efficiency
- Execute multiple independent searches simultaneously
- Reduces total research time significantly

### Task Management
- **Use TodoWrite from the start**
- Mark tasks in_progress when starting
- Mark completed immediately after finishing
- Provides user visibility into progress

### Folder Naming
Automatic conversion to folder-friendly names:
- `"How will AI impact healthcare?"` → `2025-11-10-how-will-ai-impact-healthcare`
- `"ClickHouse vs StarRocks"` → `2025-11-10-clickhouse-vs-starrocks`

### Security
- **Default**: Secure mode (recommended)
- **Dangerous mode**: Only for trusted queries requiring file/system access
- Interactive mode requires explicit confirmation

### Expected Duration
- Quick: ~10 minutes
- Standard: ~20 minutes
- Deep: ~40 minutes

Actual time varies by query complexity and web search speed.

## Files Not to Modify

- `outputs/` - Research outputs (can be deleted for cleanup)
- `examples/` - Reference examples of completed research
- `.gitignore` - Standard ignore patterns

## Troubleshooting

### Research Quality Issues
**Problem**: Missing citations or confidence markers
**Solution**: The orchestration prompt now makes these mandatory - Claude should follow the standards automatically

**Problem**: Single-source claims
**Solution**: Prompt requires 3-5 sources per major claim - verify research followed guidelines

### Performance Issues
**Problem**: Research taking too long
**Solution**:
- Ensure parallel WebSearch calls are being used
- Consider using quick mode for initial scoping
- Check if web searches are timing out

**Problem**: Insufficient depth
**Solution**: Use deep mode with verification for critical research

### Output Issues
**Problem**: Missing verification report
**Solution**: Only included in deep mode - check depth setting

**Problem**: Incomplete bibliography
**Solution**: Each assistant should include sources section - verify all assistants followed template

## Migration from v1.0

### Key Changes
1. **No more worktrees**: Git worktrees removed - simpler architecture
2. **Quality controls**: Citations and confidence now mandatory
3. **Depth modes**: Three explicit depth levels replace implicit complexity
4. **Verification**: New verification phase for deep research
5. **Focus areas**: Optional targeting of specific research dimensions

### Backward Compatibility
- Basic command line usage unchanged: `./ccheavy.sh "query"`
- Output structure mostly compatible (adds ra-verification.md in deep mode)
- Examples from v1.0 remain valid reference materials

### Migration Steps
1. Update to new script (automatic when pulling repo)
2. Review new depth modes (quick/standard/deep)
3. Familiarize with citation requirements
4. Use enhanced quality controls in new research

## Advanced Features

### Focus Areas
Target specific aspects of research:
```bash
./ccheavy.sh "Future of AI" markdown --depth=deep --focus=ethics,safety,regulation
```

The prompt will emphasize these areas while maintaining comprehensive coverage.

### Verification Mode
Deep research automatically includes cross-verification:
- RA-V reviews all assistant findings
- Checks for contradictions
- Validates benchmark claims
- Identifies bias or missing perspectives
- Flags uncertainty

### Confidence Scoring
Three levels guide interpretation:
- 🟢 **HIGH**: Trust for decisions, multiple sources confirm
- 🟡 **MEDIUM**: Generally reliable, verify if critical
- 🔴 **LOW**: Treat as preliminary, requires more research

## Best Practices Summary

1. **Always use TodoWrite** for task tracking
2. **Execute searches in parallel** for speed
3. **Follow citation standards** - every claim needs a source
4. **Mark confidence levels** - helps readers assess reliability
5. **Use deep mode** for critical decisions
6. **Respect depth recommendations** - don't over/under-allocate assistants
7. **Cross-verify important facts** - especially for business decisions
8. **Note information currency** - "As of [date]" for time-sensitive data
9. **Acknowledge gaps** - better to admit uncertainty than guess
10. **Synthesize comprehensively** - integrate all perspectives

## Support and Feedback

For issues or suggestions:
- GitHub Issues: https://github.com/gtrusler/claude-code-heavy/issues
- Review examples in `examples/` directory
- Check README.md for usage examples
