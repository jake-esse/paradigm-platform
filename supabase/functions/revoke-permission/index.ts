import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const token = authHeader.replace('Bearer ', '')

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Verify the JWT token and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const { 
      permission_id,
      app_id,
      data_type 
    } = await req.json()

    // Support revocation by either permission_id or app_id + data_type
    let query = supabase
      .from('data_permissions')
      .update({ 
        revoked_at: new Date().toISOString() 
      })
      .eq('user_id', user.id)
      .is('revoked_at', null)  // Only revoke active permissions

    if (permission_id) {
      query = query.eq('id', permission_id)
    } else if (app_id && data_type) {
      query = query.eq('app_id', app_id).eq('data_type', data_type)
    } else {
      return new Response(
        JSON.stringify({ 
          error: 'Provide either permission_id or both app_id and data_type' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const { data, error } = await query.select().single()

    if (error || !data) {
      return new Response(
        JSON.stringify({ 
          error: 'Permission not found or already revoked' 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create audit log
    await supabase
      .from('permission_audit_log')
      .insert({
        user_id: user.id,
        app_id: data.app_id,
        action: 'permission_revoked',
        data_type: data.data_type,
        details: {
          permission_id: data.id,
          revoked_at: new Date().toISOString()
        }
      })

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Permission revoked successfully',
        revoked_permission: data
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
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
