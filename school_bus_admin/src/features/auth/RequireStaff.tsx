import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from './useAuth'

/** Chặn ở giao diện cho đỡ nhầm. Dữ liệu chỉ an toàn khi RLS ở database từ chối. */
export function RequireStaff() {
  const { session, profile, loading } = useAuth()

  if (loading) {
    return <div className="grid h-screen place-items-center text-muted-ink">Đang tải...</div>
  }
  if (!session || !profile) return <Navigate to="/login" replace />
  return <Outlet />
}
