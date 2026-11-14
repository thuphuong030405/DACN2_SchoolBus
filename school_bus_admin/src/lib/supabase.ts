import { createClient } from '@supabase/supabase-js';

// Thay thế các chuỗi bên dưới bằng URL và Anon Key thực tế từ dự án Supabase của bạn
const supabaseUrl = 'https://zimlasyxfrgtsmftadjy.supabase.co';
const supabaseAnonKey = 'sb_publishable_pCeypEOyk1lPUwVrRfGSdA_wk-3gJ5S';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
})

  // Client phụ chỉ dùng để tạo tài khoản nhân sự mới mà không ghi đè session của Admin
  export const supabaseSignupClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      storageKey: 'sb-signup-helper-token',
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
});