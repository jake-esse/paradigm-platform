import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with SERVICE ROLE key for elevated privileges
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get request body
    const { 
      app_id, 
      user_id,
      data_type, 
      permission_level, 
      purpose,
      duration_days 
    } = await req.json()

    // Validate required fields
    if (!app_id || !data_type || !permission_level || !purpose) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields',
          required: ['app_id', 'data_type', 'permission_level', 'purpose']
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Validate permission level
    if (!['read', 'write', 'read-write'].includes(permission_level)) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid permission_level. Must be: read, write, or read-write' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create the permission request
    const { data, error } = await supabase
      .from('permission_requests')
      .insert({
        app_id,
        user_id: user_id || null,
        data_type,
        permission_level,
        purpose,
        requested_duration: duration_days ? `${duration_days} days` : null,
        status: 'pending'
      })
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: error.message }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Return success response
    return new Response(
      JSON.stringify({ 
        success: true,
        request_id: data.id,
        status: 'pending',
        message: 'Permission request created successfully',
        data
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