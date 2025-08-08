# Paradigm Platform - Master Context

## Project State
- **Current Phase**: Building MVP
- **Last Updated**: [Today's date]
- **Development Mode": Controlled iteration with Claude Code

## What We've Built
✅ Permission system (request, grant, check, revoke)
✅ Database schema with RLS policies  
✅ Edge Functions for permission APIs
✅ Test interface (test-system.html)

## Currently Building
🚧 User authentication system

## Architecture Rules
1. **Supabase First**: Use Supabase features before building custom
2. **Simple Over Smart**: Basic solutions that work > complex optimizations
3. **Test Everything**: Each feature needs a test interface
4. **No Premature Optimization**: Build for 100 users, not 1 million

## Code Standards
- Single responsibility: Each file does ONE thing
- Explicit naming: Long clear names > short cryptic ones  
- Comments for "why", not "what"
- Maximum file length: 200 lines (split if larger)

## File Organization
- /supabase - All Supabase config and migrations
- /extensions - Platform-specific features
- /tests - Test interfaces (HTML files for now)
- /sdk - Developer SDK (coming soon)
- /docs - User-facing documentation

## Development Boundaries
DO NOT let Claude Code:
- Refactor working code without permission
- Add features not explicitly requested
- Create complex abstractions
- Build "nice to have" features

ALWAYS tell Claude Code:
- The ONE specific task to complete
- Where to put the files
- To keep existing code unchanged unless specified

## Tech Stack Decisions
- Database: Supabase (PostgreSQL)
- Auth: Supabase Auth
- APIs: Supabase Edge Functions  
- Frontend: Simple HTML/JS for now (no framework)
- Hosting: Local development only currently