# Claude Code Development Workflow

## Before Starting Any Task

1. **Update Project State** in CLAUDE.md
2. **Create Feature Branch** (even locally)
3. **Define Success Criteria** - what exactly should work when done?

## Prompt Template for Claude Code

Always structure requests like this:
Context: [What exists now]
Task: [ONE specific thing to build]
Location: [Exactly where files should go]
Constraints: [What NOT to do]
Success: [How we verify it works]

## Example Good Prompt

Context: I have a permission system with Edge Functions working
Task: Add email/password authentication to the platform
Location: New files in /extensions/auth/, migration in /supabase/migrations/
Constraints: Don't modify existing permission code, no social login, keep it simple
Success: Users can sign up, log in, and existing permission system uses their real ID

## Example Bad Prompt

Add user authentication with all best practices and make it production-ready

## After Claude Code Generates

1. **Review Every Line** - Understand what it does
2. **Test Incrementally** - Don't wait until "done"  
3. **Document Changes** - Update relevant CLAUDE.md files
4. **Commit Working State** - Before moving to next task

## Red Flags to Watch For

Claude Code might be overengineering if you see:
- Abstract base classes
- Generic utility functions
- "Future-proofing" code
- Files over 200 lines
- Multiple features in one response

If this happens, stop and ask for simpler version.

## Testing Checklist

Before considering any feature "done":
- [ ] Manual test passes
- [ ] Error cases handled
- [ ] Existing features still work
- [ ] Code is under 200 lines per file
- [ ] You understand every line