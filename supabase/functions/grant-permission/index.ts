import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get service client for system operations
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request
    const { 
      request_id,
      user_id,
      expires_in_days 
    } = await req.json()

    // Validate inputs
    if (!request_id || !user_id) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: request_id and user_id' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 1. Get the permission request
    const { data: request, error: requestError } = await supabase
      .from('permission_requests')
      .select('*')
      .eq('id', request_id)
      .eq('status', 'pending')
      .single()

    if (requestError || !request) {
      return new Response(
        JSON.stringify({ 
          error: 'Permission request not found or already processed' 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Calculate expiration date
    let expires_at = null
    if (expires_in_days) {
      const expirationDate = new Date()
      expirationDate.setDate(expirationDate.getDate() + expires_in_days)
      expires_at = expirationDate.toISOString()
    }

    // 3. Create the permission grant
    const { data: permission, error: permissionError } = await supabase
      .from('data_permissions')
      .insert({
        user_id,
        app_id: request.app_id,
        data_type: request.data_type,
        permission_level: request.permission_level,
        purpose: request.purpose,
        expires_at,
        granted_at: new Date().toISOString()
      })
      .select()
      .single()

    if (permissionError) {
      return new Response(
        JSON.stringify({ 
          error: 'Failed to grant permission: ' + permissionError.message 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4. Update the request status
    await supabase
      .from('permission_requests')
      .update({ 
        status: 'approved',
        responded_at: new Date().toISOString()
      })
      .eq('id', request_id)

    // 5. Create audit log entry
    await supabase
      .from('permission_audit_log')
      .insert({
        user_id,
        app_id: request.app_id,
        action: 'permission_granted',
        data_type: request.data_type,
        details: {
          request_id,
          permission_id: permission.id,
          expires_at,
          permission_level: request.permission_level
        }
      })

    // Return success
    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Permission granted successfully',
        permission: {
          id: permission.id,
          app_id: request.app_id,
          data_type: request.data_type,
          permission_level: request.permission_level,
          expires_at
        }
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
