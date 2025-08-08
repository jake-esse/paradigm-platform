-- Enable Row Level Security on all tables
ALTER TABLE apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE permission_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE permission_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_data ENABLE ROW LEVEL SECURITY;

-- ========================
-- APPS TABLE POLICIES
-- ========================

-- Everyone can view active apps (like an app store)
CREATE POLICY "Public apps are viewable by everyone" 
    ON apps FOR SELECT 
    USING (is_active = true);

-- Developers can insert their own apps (when we add auth)
CREATE POLICY "Developers can create apps" 
    ON apps FOR INSERT 
    WITH CHECK (auth.uid() = developer_id);

-- Developers can update their own apps
CREATE POLICY "Developers can update own apps" 
    ON apps FOR UPDATE 
    USING (auth.uid() = developer_id);

-- ========================
-- DATA TYPES POLICIES
-- ========================

-- Everyone can see available data types
CREATE POLICY "Data types are public" 
    ON data_types FOR SELECT 
    USING (true);

-- ========================
-- PERMISSIONS POLICIES
-- ========================

-- Users can only see their own permissions
CREATE POLICY "Users can view own permissions" 
    ON data_permissions FOR SELECT 
    USING (auth.uid() = user_id);

-- Users can grant permissions (insert)
CREATE POLICY "Users can grant permissions" 
    ON data_permissions FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can revoke permissions (update)
CREATE POLICY "Users can revoke permissions" 
    ON data_permissions FOR UPDATE 
    USING (auth.uid() = user_id);

-- ========================
-- USER DATA POLICIES
-- ========================

-- Users can see their own data
CREATE POLICY "Users own their data" 
    ON user_data FOR SELECT 
    USING (auth.uid() = user_id);

-- Users can insert their own data
CREATE POLICY "Users can create data" 
    ON user_data FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own data
CREATE POLICY "Users can update data" 
    ON user_data FOR UPDATE 
    USING (auth.uid() = user_id);

-- Users can delete their own data
CREATE POLICY "Users can delete data" 
    ON user_data FOR DELETE 
    USING (auth.uid() = user_id);

-- Apps can read data they have permission for (using our function)
CREATE POLICY "Apps can read permitted data" 
    ON user_data FOR SELECT 
    USING (
        check_app_permission(app_id, user_id, data_type, 'read')
    );

-- ========================
-- AUDIT LOG POLICIES
-- ========================

-- Users can view their own audit history
CREATE POLICY "Users can view own audit log" 
    ON permission_audit_log FOR SELECT 
    USING (auth.uid() = user_id);

-- System can insert audit logs (handled by trigger)
CREATE POLICY "System can create audit logs" 
    ON permission_audit_log FOR INSERT 
    WITH CHECK (true);

-- ========================
-- PERMISSION REQUESTS POLICIES
-- ========================

-- Users can see requests for their data
CREATE POLICY "Users can view permission requests" 
    ON permission_requests FOR SELECT 
    USING (auth.uid() = user_id OR user_id IS NULL);

-- Apps can create permission requests
CREATE POLICY "Apps can request permissions" 
    ON permission_requests FOR INSERT 
    WITH CHECK (true);  -- Will refine this when we add app authentication

-- Users can respond to requests (update status)
CREATE POLICY "Users can respond to requests" 
    ON permission_requests FOR UPDATE 
    USING (auth.uid() = user_id OR user_id IS NULL);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '🔒 Row Level Security enabled on all tables!';
  RAISE NOTICE '✅ Security policies created successfully!';
END $$;