# Supabase Configuration

## Database Principles
- User data sovereignty via RLS
- Simple table structures
- Avoid premature optimization

## Edge Function Rules  
- Each function does ONE thing
- Always validate inputs
- Return consistent error formats
- Use service role key sparingly

## Migration Guidelines
- One migration per feature
- Always include rollback SQL
- Test on local before production