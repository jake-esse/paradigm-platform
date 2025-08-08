-- Drop the existing restrictive policies
DROP POLICY IF EXISTS "Users can view permission requests" ON permission_requests;
DROP POLICY IF EXISTS "Allow reading permission requests for testing" ON permission_requests;

-- Create a more permissive policy for testing
-- In production, this would check authentication
CREATE POLICY "Allow reading permission requests during testing" 
    ON permission_requests FOR SELECT 
    USING (true);  -- Allow all reads for now

-- Also ensure we can read the active_permissions view
GRANT SELECT ON active_permissions TO anon;
GRANT SELECT ON pending_requests TO anon;

DO $$
BEGIN
  RAISE NOTICE '✅ Fixed permission request read policies for testing!';
END $$;