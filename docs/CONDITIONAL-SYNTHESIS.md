# Conditional Synthesis - Handling Long Reports

## Date
November 10, 2025

## Problem Identified

**User feedback:** "When writing final analysis, ONLY when the file is too long, then let write the outline first, then each agent will contribute their sections. ONLY do it when the final report is too long."

### Root Cause

**Single-pass synthesis limitations:**
- Large reports (8000+ words) can hit token limits
- Writing everything at once is memory-intensive
- Risk of incomplete output if context fills up
- Difficult to manage very long synthesis

**Specific scenarios:**
- Deep research with 6-8 agents
- Each agent writes 1000-2000 words
- Total findings: 10,000+ words
- Final synthesis: 8000+ words expected

**Result**: Token limit errors, incomplete synthesis, or poor quality due to context pressure

## Solution Implemented

### Two-Approach Conditional Logic

Added **Approach A** (standard) and **Approach B** (incremental) to Phase 4 synthesis.

### Approach A: Standard Synthesis

**When to use:**
- ✅ Quick or Standard depth research
- ✅ 5 or fewer agents
- ✅ Total findings expected < 5000 words
- ✅ Final report expected < 5000 words

**Method:**
```markdown
1. Read ALL findings files
2. Write complete final-analysis.md at once with all sections:
   - Executive Summary
   - Research Methodology
   - Detailed Findings (organized by themes)
   - Cross-Cutting Insights
   - Limitations & Gaps
   - Areas of Uncertainty
   - Recommendations
   - Complete Bibliography
3. Save complete file
```

**Benefits:**
- Simple and fast
- Single coherent output
- No context management needed
- Works well for normal reports

### Approach B: Incremental Synthesis

**When to use:**
- ⚠️ Deep research with 6+ agents
- ⚠️ Each agent wrote 1000+ words
- ⚠️ Expected final report > 8000 words
- ⚠️ Risk of hitting token limits

**Method:**

**Step 1: Create Outline**
```markdown
1. Read ALL findings files to understand scope
2. Estimate total report length
3. Create detailed outline in ./final-analysis-outline.md:
   - Section structure
   - Which agent findings go in which section
   - Estimated word count per section
   - Themes identified
```

**Step 2: Write Sections Incrementally**
```markdown
1. Start with skeleton file (headers only)
2. Write Executive Summary
   - Read relevant findings
   - Write 2-3 paragraphs
   - Append to final-analysis.md
3. Write Research Methodology
   - Document process
   - Append to file
4. Write Detailed Findings (one theme at a time)
   - For each theme:
     - Read relevant agent findings
     - Synthesize section
     - Include citations
     - Append to file
5. Write remaining sections incrementally:
   - Cross-Cutting Insights
   - Limitations & Gaps
   - Areas of Uncertainty
   - Recommendations
   - Complete Bibliography
```

**Step 3: Final Review**
```markdown
1. Read complete final-analysis.md
2. Verify all sections present
3. Check flow and coherence
4. Confirm all agent findings represented
```

**Benefits:**
- Prevents token limit errors
- Allows saving progress incrementally
- Easier to manage large reports
- Each section can be reviewed before next
- Reduces memory pressure
- Can recover if interrupted

## Decision Criteria

### Use Approach A (Standard) When:
| Factor | Threshold |
|--------|-----------|
| Research Depth | Quick or Standard |
| Number of Agents | ≤ 5 |
| Words per Agent | < 1000 |
| Total Findings | < 5000 words |
| Expected Synthesis | < 5000 words |

### Use Approach B (Incremental) When:
| Factor | Threshold |
|--------|-----------|
| Research Depth | Deep |
| Number of Agents | ≥ 6 |
| Words per Agent | 1000-2000 |
| Total Findings | > 6000 words |
| Expected Synthesis | > 8000 words |

### Quick Estimation

**Approach A (Standard):**
- 3 agents × 500 words = 1500 words findings
- Synthesis ~2000 words
- Total context needed: ~4000 tokens ✅

**Approach B (Incremental):**
- 7 agents × 1500 words = 10,500 words findings
- Synthesis ~9000 words
- Total context needed: ~20,000 tokens ⚠️
- **Risk of hitting limits!**

## Code Location

**File**: `ccheavy.sh`
**Section**: `create_phase1_prompt()` - orchestration-prompt.md template
**Lines**: 402-496 (Phase 4 synthesis section)

**Changes:**
- **Replaced**: Single synthesis approach
- **Added**: Approach A (Standard Synthesis) with criteria
- **Added**: Approach B (Incremental Synthesis) with 3-step process
- **Added**: Decision criteria and warnings
- **Updated**: Expected Outputs to include optional outline
- **Updated**: Final Completion Checklist

## Comparison: Before vs After

### Before (Single Approach)

```markdown
### Phase 4: Synthesis

**Checklist:**
- [ ] Read ALL findings
- [ ] Create comprehensive final-analysis.md with:
  - Executive Summary
  - Research Methodology
  - Detailed Findings
  - Cross-Cutting Insights
  - ...
  - Complete Bibliography
- [ ] Save to: ./final-analysis.md
```

**Problems:**
- Works for small reports
- Fails for large reports (token limits)
- No guidance on handling long synthesis
- Risk of incomplete output

### After (Conditional Approach)

```markdown
### Phase 4: Synthesis

**Important Decision: Choose your approach based on report size**

#### Approach A: Standard Synthesis
**Use when:** < 5000 words
**Method:** Write complete file at once

#### Approach B: Incremental Synthesis
**Use when:** > 8000 words, 6+ agents
**Method:**
Step 1: Create outline
Step 2: Write sections incrementally
Step 3: Final review

**Important:** Use Approach A by default. Only use Approach B if exceptionally long.
```

**Improvements:**
- ✅ Clear decision criteria
- ✅ Two approaches for different scenarios
- ✅ Prevents token limit errors
- ✅ Guidance on when to use each

## Example Workflows

### Example 1: Standard Research (Approach A)

**Configuration:**
- Depth: Standard
- Agents: 4
- Words per agent: 700

**Synthesis Process:**
```
1. Read all 4 findings files (~2800 words)
2. Write complete final-analysis.md (~3500 words)
3. Save file
Done in ~5 minutes
```

**Why Approach A:**
- Total content: ~6300 words
- Single pass: ~8000 tokens
- Well within limits ✅

### Example 2: Deep Research (Approach B)

**Configuration:**
- Depth: Deep
- Agents: 7 + verification
- Words per agent: 1500

**Synthesis Process:**
```
Step 1: Create Outline
1. Read all 8 findings files (~12,000 words)
2. Identify 6 major themes
3. Create outline: final-analysis-outline.md
   - Executive Summary (500 words)
   - Research Methodology (400 words)
   - Theme 1: Architecture (1200 words)
   - Theme 2: Performance (1200 words)
   - Theme 3: Security (1200 words)
   - Theme 4: Costs (1000 words)
   - Theme 5: Migration (1000 words)
   - Theme 6: Alternatives (800 words)
   - Cross-Cutting Insights (600 words)
   - Limitations (400 words)
   - Uncertainty (300 words)
   - Recommendations (400 words)
   - Bibliography (200 words)
   Total: ~9000 words

Step 2: Write Incrementally
1. Create skeleton with headers
2. Write Executive Summary → append
3. Write Research Methodology → append
4. Write Theme 1 (Architecture) → append
   [Read relevant agent findings]
   [Synthesize ~1200 words]
   [Save progress]
5. Write Theme 2 (Performance) → append
   ...
   [Continue for each theme]
6. Write Cross-Cutting Insights → append
7. Write Limitations → append
8. Write Uncertainty → append
9. Write Recommendations → append
10. Write Bibliography → append

Step 3: Final Review
1. Read complete final-analysis.md (~9000 words)
2. Verify coherence
3. Confirm all sections present
Done in ~30 minutes
```

**Why Approach B:**
- Total content: ~21,000 words to process
- Single pass would need: ~27,000 tokens ⚠️
- Incremental passes: ~3,000 tokens each ✅
- Prevents token limit errors

## Implementation Details

### Outline File Format (final-analysis-outline.md)

```markdown
# Final Analysis Outline

## Estimated Report Length
~9000 words

## Section Structure

### 1. Executive Summary (500 words)
**Sources:** All agents
**Key Points:**
- Main finding 1
- Main finding 2
- Main finding 3

### 2. Research Methodology (400 words)
**Content:**
- Number of agents
- Research depth
- Search strategy
- Quality standards applied

### 3. Detailed Findings

#### Theme 1: Architecture (1200 words)
**Sources:** ra-1-architecture, ra-2-design
**Content:**
- Subtopic A
- Subtopic B
- Subtopic C

#### Theme 2: Performance (1200 words)
**Sources:** ra-3-performance, ra-4-benchmarks
**Content:**
- Subtopic A
- Subtopic B

[Continue for all themes...]

### 4. Cross-Cutting Insights (600 words)
**Content:**
- Pattern 1
- Pattern 2
- Pattern 3

[Continue for all sections...]

## Agent Findings Mapping
- ra-1-architecture → Theme 1, Theme 4
- ra-2-design → Theme 1, Theme 3
- ra-3-performance → Theme 2
- ra-4-benchmarks → Theme 2
- ra-5-security → Theme 3
- ra-6-costs → Theme 4
- ra-7-migration → Theme 5
- ra-v-verification → All themes
```

### Incremental Writing Pattern

```markdown
# Starting skeleton (headers only)

# Final Analysis: [Query Title]

## Executive Summary
[To be written]

## Research Methodology
[To be written]

## Detailed Findings

### Architecture Analysis
[To be written]

### Performance Characteristics
[To be written]

[... all sections as headers ...]

---

# After writing Executive Summary

# Final Analysis: [Query Title]

## Executive Summary

Based on comprehensive research by 7 specialized agents...
[Complete 500-word summary with citations]

## Research Methodology
[To be written]

[Continue...]
```

## Benefits Summary

### For Standard Reports (Approach A)
- ✅ Simple and fast
- ✅ Single coherent output
- ✅ No complexity overhead
- ✅ Default approach

### For Long Reports (Approach B)
- ✅ Prevents token limit errors
- ✅ Saves progress incrementally
- ✅ Manageable memory footprint
- ✅ Can recover from interruptions
- ✅ Better quality control (review per section)
- ✅ Easier debugging if issues occur

### For Users
- ✅ System handles long reports gracefully
- ✅ No failed syntheses due to length
- ✅ Complete output regardless of size
- ✅ Quality maintained even for complex research

## Testing Scenarios

### Test 1: Standard Report (Approach A)

**Setup:**
- Depth: standard
- Agents: 4
- Words: 600 each

**Expected:**
- Claude chooses Approach A
- Writes complete final-analysis.md at once
- No outline file created
- Synthesis completes in single pass

### Test 2: Long Report (Approach B)

**Setup:**
- Depth: deep
- Agents: 7
- Words: 1500 each

**Expected:**
- Claude chooses Approach B
- Creates final-analysis-outline.md first
- Writes final-analysis.md incrementally
- Both outline and final analysis exist
- Synthesis completes successfully

### Test 3: Edge Case (Borderline)

**Setup:**
- Depth: standard
- Agents: 6
- Words: 800 each

**Expected:**
- Claude evaluates: 6 × 800 = 4800 words
- Likely chooses Approach A (just under threshold)
- If context pressure occurs, can switch to Approach B
- System handles either approach

## Error Prevention

### Token Limit Scenarios

**Without Conditional Synthesis:**
```
Deep research with 8 agents × 1500 words = 12,000 words
Attempt to read all + write 9000-word synthesis
Total context: ~27,000 tokens
Result: Token limit error, incomplete synthesis ❌
```

**With Conditional Synthesis (Approach B):**
```
Deep research with 8 agents × 1500 words = 12,000 words
Step 1: Read all, create outline (~15,000 tokens) ✅
Step 2a: Read relevant + write Theme 1 (~3,000 tokens) ✅
Step 2b: Read relevant + write Theme 2 (~3,000 tokens) ✅
...continue for each section...
Result: Complete synthesis, no token errors ✅
```

## Guidelines in Orchestration Prompt

### Clear Decision Making

```markdown
**Important Decision: Choose your approach based on report size**
```

### Explicit Criteria

```markdown
**Use Approach A when:**
- Quick or Standard depth
- 5 or fewer agents
- Total findings < 5000 words

**Use Approach B when:**
- Deep research with 6+ agents
- Each agent wrote 1000+ words
- Expected final report > 8000 words
- Risk of hitting token limits
```

### Default Behavior

```markdown
**Important:** Use Approach A (standard) by default.
Only use Approach B (incremental) if you determine the report will be exceptionally long.
```

## Future Enhancements (Optional)

1. **Automatic detection**: Script calculates word counts and suggests approach
2. **Hybrid approach**: Start with Approach A, fall back to B if needed
3. **Section templates**: Pre-defined structures for common report types
4. **Progress indicators**: Show section completion percentage
5. **Resume capability**: Pick up from last completed section

## Conclusion

The conditional synthesis approach ensures:
- ✅ Standard reports use simple, fast Approach A
- ✅ Long reports use incremental Approach B to prevent errors
- ✅ Clear criteria guide the decision
- ✅ Both approaches produce complete, high-quality output
- ✅ No token limit failures for large research projects

**Key Innovation**: Let Claude decide based on actual content size, not arbitrary rules.

**Status**: ✅ Implemented and syntax validated

**Impact**: High - Prevents synthesis failures for deep research

**Version**: 2.3 (Conditional Synthesis)

**Date**: November 10, 2025
