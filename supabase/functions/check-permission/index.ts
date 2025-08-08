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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { 
      app_id,
      user_id,
      data_type,
      permission_level 
    } = await req.json()

    // Validate inputs
    if (!app_id || !user_id || !data_type) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: app_id, user_id, data_type' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check for active permission using the database function
    const { data: hasPermission, error } = await supabase
      .rpc('check_app_permission', {
        p_app_id: app_id,
        p_user_id: user_id,
        p_data_type: data_type,
        p_permission_level: permission_level || 'read'
      })

    if (error) {
      console.error('Error checking permission:', error)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to check permission' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get permission details if it exists
    let permissionDetails = null
    if (hasPermission) {
      const { data } = await supabase
        .from('active_permissions')
        .select('*')
        .eq('app_id', app_id)
        .eq('user_id', user_id)
        .eq('data_type', data_type)
        .single()
      
      permissionDetails = data
    }

    return new Response(
      JSON.stringify({ 
        has_permission: hasPermission,
        permission: permissionDetails,
        checked_at: new Date().toISOString()
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
