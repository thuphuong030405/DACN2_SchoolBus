import { createContext } from 'react'
import type { Session } from '@supabase/supabase-js'

export type Role = 'ADMIN' | 'SCHOOL_MANAGER' | 'PARENT' | 'TEACHER' | 'DRIVER'

export interface Profile {
  user_id: string
  full_name: string
  email: string
  role: Role
  avatar_url: string | null
  is_active: boolean
}

/** Chỉ hai vai trò này được vào Dashboard. */
export const STAFF_ROLES: Role[] = ['ADMIN', 'SCHOOL_MANAGER']

export interface AuthContextValue {
  session: Session | null
  profile: Profile | null
  loading: boolean
  /** Lý do bị từ chối (ví dụ không đủ quyền), hiển thị ở trang đăng nhập. */
  error: string | null
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)
