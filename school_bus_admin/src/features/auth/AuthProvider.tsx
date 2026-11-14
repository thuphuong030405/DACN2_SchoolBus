import { useEffect, useState, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import { AuthContext, STAFF_ROLES, type Profile } from './auth-context'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadStaffProfile = async (userId: string) => {
    const { data, error: dbErr } = await supabase
      .from('users')
      .select('user_id, full_name, email, role, avatar_url, is_active')
      .eq('user_id', userId)
      .single()

    if (dbErr || !data) {
      await supabase.auth.signOut()
      setProfile(null)
      setError('Không tìm thấy hồ sơ người dùng trong hệ thống.')
      return
    }

    const userProfile = data as Profile

    if (!userProfile.is_active) {
      await supabase.auth.signOut()
      setProfile(null)
      setError('Tài khoản của bạn đã bị vô hiệu hóa.')
      return
    }

    if (!STAFF_ROLES.includes(userProfile.role)) {
      await supabase.auth.signOut()
      setProfile(null)
      setError('Tài khoản không có quyền truy cập Cổng Ban giám hiệu.')
      return
    }

    setError(null)
    setProfile(userProfile)
  }

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session: s } }) => {
      setSession(s)
      if (s?.user) {
        await loadStaffProfile(s.user.id)
      }
      setLoading(false)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, s) => {
      setSession(s)
      if (s?.user) {
        await loadStaffProfile(s.user.id)
      } else {
        setProfile(null)
      }
      setLoading(false)
    })

    return () => subscription.unsubscribe()
  }, [])

  const signIn = async (email: string, password: string) => {
    setError(null)
    const { data, error: authErr } = await supabase.auth.signInWithPassword({ email, password })
    if (authErr) {
      throw new Error(
        authErr.message === 'Invalid login credentials'
          ? 'Email hoặc mật khẩu không chính xác.'
          : authErr.message,
      )
    }
    if (data.user) {
      await loadStaffProfile(data.user.id)
    }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
    setSession(null)
    setProfile(null)
  }

  return (
    <AuthContext.Provider value={{ session, profile, loading, error, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}