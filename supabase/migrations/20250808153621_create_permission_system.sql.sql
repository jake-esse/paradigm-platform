-- Paradigm Platform: Complete Permission System Schema
-- This creates all tables needed for the permission system

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================
-- CORE TABLES
-- ========================

-- 1. Apps table: All applications on the platform
CREATE TABLE apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    developer_id UUID NOT NULL,
    icon_url TEXT,
    website_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT app_name_length CHECK (char_length(name) >= 3)
);

-- 2. Data types: Categories of data that apps can request
CREATE TABLE data_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    sensitivity_level TEXT NOT NULL DEFAULT 'medium',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_sensitivity CHECK (sensitivity_level IN ('low', 'medium', 'high'))
);

-- 3. Data permissions: Active permissions granted by users to apps
CREATE TABLE data_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    app_id UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
    data_type TEXT NOT NULL,
    permission_level TEXT NOT NULL,
    purpose TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_permission_level CHECK (permission_level IN ('read', 'write', 'read-write'))
);

-- 4. User data: Actual data stored by users
CREATE TABLE user_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    app_id UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
    data_type TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Permission requests: Apps requesting access to user data
CREATE TABLE permission_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
    user_id UUID,  -- Optional: can be null for general requests
    data_type TEXT NOT NULL,
    permission_level TEXT NOT NULL,
    purpose TEXT NOT NULL,
    requested_duration INTERVAL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_permission_level CHECK (permission_level IN ('read', 'write', 'read-write')),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'denied', 'expired'))
);

-- 6. Permission audit log: Track all permission changes
CREATE TABLE permission_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    app_id UUID REFERENCES apps(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    data_type TEXT,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================
-- INDEXES FOR PERFORMANCE
-- ========================

CREATE INDEX idx_permissions_user ON data_permissions(user_id);
CREATE INDEX idx_permissions_app ON data_permissions(app_id);
CREATE INDEX idx_permissions_active ON data_permissions(revoked_at, expires_at);
CREATE INDEX idx_user_data_user ON user_data(user_id);
CREATE INDEX idx_user_data_app ON user_data(app_id);
CREATE INDEX idx_audit_user ON permission_audit_log(user_id);
CREATE INDEX idx_audit_created ON permission_audit_log(created_at DESC);
CREATE INDEX idx_requests_app ON permission_requests(app_id);
CREATE INDEX idx_requests_status ON permission_requests(status);

-- ========================
-- VIEWS FOR EASIER QUERIES
-- ========================

-- View for currently active permissions
CREATE VIEW active_permissions AS
SELECT 
    dp.id,
    dp.user_id,
    a.name as app_name,
    a.id as app_id,
    a.icon_url as app_icon,
    dp.data_type,
    dp.permission_level,
    dp.purpose,
    dp.expires_at,
    dp.granted_at,
    CASE 
        WHEN dp.revoked_at IS NOT NULL THEN 'revoked'
        WHEN dp.expires_at IS NOT NULL AND dp.expires_at < NOW() THEN 'expired'
        ELSE 'active'
    END as status
FROM data_permissions dp
JOIN apps a ON dp.app_id = a.id
WHERE dp.revoked_at IS NULL 
  AND (dp.expires_at IS NULL OR dp.expires_at > NOW());

-- View for pending permission requests
CREATE VIEW pending_requests AS
SELECT 
    pr.id,
    pr.user_id,
    a.name as app_name,
    a.icon_url as app_icon,
    pr.data_type,
    pr.permission_level,
    pr.purpose,
    pr.requested_duration,
    pr.created_at
FROM permission_requests pr
JOIN apps a ON pr.app_id = a.id
WHERE pr.status = 'pending';

-- ========================
-- DEFAULT DATA
-- ========================

-- Insert default data types
INSERT INTO data_types (name, description, icon, sensitivity_level) VALUES
    ('fitness', 'Health and fitness tracking data', '💪', 'medium'),
    ('financial', 'Financial transactions and accounts', '💰', 'high'),
    ('location', 'Location and places visited', '📍', 'high'),
    ('social', 'Contacts and social connections', '👥', 'medium'),
    ('documents', 'Documents and files', '📄', 'medium'),
    ('photos', 'Photos and images', '📷', 'medium'),
    ('calendar', 'Calendar events and schedules', '📅', 'medium'),
    ('medical', 'Medical records and health data', '🏥', 'high'),
    ('preferences', 'App settings and preferences', '⚙️', 'low'),
    ('usage', 'App usage statistics and analytics', '📊', 'low'),
    ('notes', 'Personal notes and thoughts', '📝', 'medium'),
    ('audio', 'Voice recordings and audio files', '🎵', 'medium');

-- Insert a sample test app (for development)
INSERT INTO apps (name, description, developer_id, icon_url, website_url) VALUES
    ('Sample Fitness Tracker', 
     'A demo app for testing the permission system', 
     '00000000-0000-0000-0000-000000000000'::UUID,
     'https://example.com/icon.png',
     'https://example.com');

-- ========================
-- HELPER FUNCTIONS
-- ========================

-- Function to check if an app has permission to access data
CREATE OR REPLACE FUNCTION check_app_permission(
    p_app_id UUID,
    p_user_id UUID,
    p_data_type TEXT,
    p_permission_level TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM data_permissions dp
        WHERE dp.app_id = p_app_id
          AND dp.user_id = p_user_id
          AND dp.data_type = p_data_type
          AND (dp.permission_level = p_permission_level OR dp.permission_level = 'read-write')
          AND dp.revoked_at IS NULL
          AND (dp.expires_at IS NULL OR dp.expires_at > NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log permission changes
CREATE OR REPLACE FUNCTION log_permission_change() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO permission_audit_log (user_id, app_id, action, data_type, details)
    VALUES (
        COALESCE(NEW.user_id, OLD.user_id),
        COALESCE(NEW.app_id, OLD.app_id),
        TG_OP,
        COALESCE(NEW.data_type, OLD.data_type),
        jsonb_build_object(
            'old', row_to_json(OLD),
            'new', row_to_json(NEW)
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for permission changes
CREATE TRIGGER log_permission_changes
AFTER INSERT OR UPDATE OR DELETE ON data_permissions
FOR EACH ROW EXECUTE FUNCTION log_permission_change();

-- ========================
-- COMPLETION MESSAGE
-- ========================

DO $$
BEGIN
  RAISE NOTICE '✅ Permission system tables created successfully!';
  RAISE NOTICE '📊 Loaded % data types', (SELECT COUNT(*) FROM data_types);
  RAISE NOTICE '🚀 Created 1 sample app for testing';
  RAISE NOTICE '👀 Created views: active_permissions, pending_requests';
  RAISE NOTICE '🔧 Created helper functions: check_app_permission';
END $$;