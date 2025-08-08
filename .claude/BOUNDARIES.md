# Claude Code Boundaries

## NEVER Allow Claude Code To:

1. **Refactor Working Code** without explicit permission
2. **Add Bonus Features** not in the requirements
3. **Create Abstractions** for "future flexibility"
4. **Generate Files Over 200 Lines**
5. **Modify Multiple Systems** in one response
6. **Add External Dependencies** without approval
7. **Create Complex Inheritance** hierarchies
8. **Build Admin Interfaces** (not needed yet)

## ALWAYS Require Claude Code To:

1. **Keep Changes Minimal** - smallest diff that works
2. **Preserve Existing Code** unless specifically asked to change
3. **Use Descriptive Names** - clarity over brevity
4. **Add Error Handling** for every user input
5. **Include Usage Comments** for non-obvious code
6. **Specify File Locations** in responses
7. **Explain Breaking Changes** if any

## Per-Session Limits

In a single Claude Code session, limit to:
- Maximum 3 new files
- Maximum 5 file modifications  
- Maximum 500 lines total new code
- One feature or fix only

## If Claude Code Exceeds Boundaries

Say: "This response is too complex. Please break it down into smaller steps and let's start with just [specific part]."