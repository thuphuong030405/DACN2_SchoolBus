import { useEffect, useState } from 'react'
import { NavLink, Outlet, createBrowserRouter, RouterProvider } from 'react-router-dom'
import {
  Bell,
  Bus,
  CalendarOff,
  ClipboardCheck,
  LayoutDashboard,
  LogOut,
  MapPin,
  Route as RouteIcon,
  ScanFace,
  Search,
  TriangleAlert,
  UsersRound,
  Users,
  ShieldAlert,
  CheckCircle2,
  type LucideIcon,
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

// ==========================================
// 1. APP SHELL (Layout chính với Sidebar & Header)
// ==========================================
type NavItem = {
  to: string
  label: string
  icon: LucideIcon
  end?: boolean
  badge?: number
}

const BASE_NAV: NavItem[] = [
  { to: '/', label: 'Tổng quan', icon: LayoutDashboard, end: true },
  { to: '/fleet', label: 'Giám sát đội xe', icon: MapPin },
  { to: '/students', label: 'Học sinh & khuôn mặt', icon: ScanFace },
  { to: '/staff', label: 'Tài xế & bảo mẫu', icon: UsersRound },
  { to: '/routes', label: 'Xe & tuyến đường', icon: RouteIcon },
  { to: '/attendance', label: 'Điểm danh', icon: ClipboardCheck },
  { to: '/absences', label: 'Đơn xin nghỉ', icon: CalendarOff },
  { to: '/alerts', label: 'Cảnh báo', icon: TriangleAlert },
]

export function AppShell() {
  const [email, setEmail] = useState('')
  const [openAlerts, setOpenAlerts] = useState(0)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setEmail(data.session?.user.email ?? '')
    })
  }, [])

  useEffect(() => {
    let off = false
    supabase
      .from('alerts')
      .select('*', { count: 'exact', head: true })
      .in('status', ['OPEN', 'PROCESSING'])
      .then(({ count }) => {
        if (!off) setOpenAlerts(count ?? 0)
      })
    return () => {
      off = true
    }
  }, [])

  const nav = BASE_NAV.map((n) =>
    n.to === '/alerts' ? { ...n, badge: openAlerts } : n,
  )

return (
    // 1. Khóa cứng chiều cao bằng đúng màn hình (h-screen) và chặn cuộn trang ngoài (overflow-hidden)
    <div className="flex h-screen w-full overflow-hidden bg-[#F3F6FC] text-[#0F172A]">
      {/* ===== THANH BÊN (SIDEBAR CỐ ĐỊNH) ===== */}
      <aside className="flex h-full w-[252px] shrink-0 flex-col gap-6 bg-[#0F2150] px-4 py-5 text-white">
        <div className="flex items-center gap-3 px-2">
          <span className="grid size-10 place-items-center rounded-xl bg-[#FACC15] text-[#0F172A]">
            <Bus className="size-5 stroke-[2.2]" />
          </span>
          <div className="leading-tight">
            <b className="block text-[15px] font-bold">Bus An Toàn</b>
            <span className="text-xs text-white/60">Ban giám hiệu</span>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1 overflow-y-auto">
          {nav.map(({ to, label, icon: Icon, end, badge }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${
                  isActive
                    ? 'bg-[#FACC15] text-[#0F172A]'
                    : 'text-white/75 hover:bg-white/10 hover:text-white'
                }`
              }
            >
              <Icon className="size-[18px] shrink-0" />
              <span className="truncate">{label}</span>
              {badge ? (
                <span className="ml-auto grid min-w-5 place-items-center rounded-full bg-[#EF4444] px-1.5 text-[11px] font-bold text-white">
                  {badge}
                </span>
              ) : null}
            </NavLink>
          ))}
        </nav>

        <div className="flex items-center gap-3 rounded-2xl bg-white/[0.07] p-3">
          <span className="grid size-9 shrink-0 place-items-center rounded-full bg-[#2563EB] text-sm font-bold">
            {(email || 'B').charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0 flex-1 leading-tight">
            <b className="block truncate text-[13px] font-semibold">
              {email || 'Ban giám hiệu'}
            </b>
            <span className="text-[11px] text-white/60">Quản trị</span>
          </div>
          <button
            type="button"
            title="Đăng xuất"
            onClick={() => void supabase.auth.signOut()}
            className="grid size-8 place-items-center rounded-lg text-white/70 hover:bg-white/10 hover:text-white"
          >
            <LogOut className="size-4" />
          </button>
        </div>
      </aside>

      {/* ===== PHẦN BÊN PHẢI (CUỘN ĐỘC LẬP) ===== */}
      <div className="flex min-w-0 flex-1 flex-col overflow-y-auto">
        <header className="flex shrink-0 items-center justify-end gap-3 px-6 pt-5 lg:px-8">
          <label className="flex h-11 w-full max-w-[340px] items-center gap-2.5 rounded-2xl bg-white px-4 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.12)]">
            <Search className="size-4 shrink-0 text-[#64748B]" />
            <input
              placeholder="Tìm học sinh, xe, tuyến..."
              className="w-full bg-transparent text-sm outline-none placeholder:text-[#94A3B8]"
            />
          </label>
          <button
            type="button"
            title="Thông báo"
            className="relative grid size-11 shrink-0 place-items-center rounded-2xl bg-white shadow-[0_2px_10px_-4px_rgba(15,23,42,0.12)]"
          >
            <Bell className="size-[18px]" />
            {openAlerts > 0 && (
              <span className="absolute right-2.5 top-2.5 size-2 rounded-full bg-[#EF4444]" />
            )}
          </button>
        </header>

        <main className="flex-1 px-6 pb-10 pt-5 lg:px-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

// ==========================================
// 2. CÁC TRANG CHỨC NĂNG (PAGES)
// ==========================================

// Trang Tổng quan
export function OverviewPage() {
  const [stats, setStats] = useState({ buses: 0, students: 0, drivers: 0, alerts: 0 })

  useEffect(() => {
    async function fetchStats() {
      const [buses, students, drivers, alerts] = await Promise.all([
        supabase.from('buses').select('*', { count: 'exact', head: true }),
        supabase.from('students').select('*', { count: 'exact', head: true }),
        supabase.from('staff').select('*', { count: 'exact', head: true }),
        supabase.from('alerts').select('*', { count: 'exact', head: true }).in('status', ['OPEN', 'PROCESSING']),
      ])
      setStats({
        buses: buses.count ?? 0,
        students: students.count ?? 0,
        drivers: drivers.count ?? 0,
        alerts: alerts.count ?? 0,
      })
    }
    fetchStats()
  }, [])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Tổng quan hệ thống</h1>
        <p className="text-sm text-[#64748B]">Theo dõi hoạt động xe buýt đưa đón học sinh thời gian thực.</p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div className="flex items-center gap-4 rounded-2xl bg-white p-5 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
          <div className="grid size-12 place-items-center rounded-xl bg-blue-50 text-blue-600"><Bus className="size-6" /></div>
          <div>
            <span className="text-sm text-[#64748B]">Tổng số xe</span>
            <h2 className="text-xl font-bold">{stats.buses}</h2>
          </div>
        </div>
        <div className="flex items-center gap-4 rounded-2xl bg-white p-5 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
          <div className="grid size-12 place-items-center rounded-xl bg-emerald-50 text-emerald-600"><Users className="size-6" /></div>
          <div>
            <span className="text-sm text-[#64748B]">Học sinh</span>
            <h2 className="text-xl font-bold">{stats.students}</h2>
          </div>
        </div>
        <div className="flex items-center gap-4 rounded-2xl bg-white p-5 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
          <div className="grid size-12 place-items-center rounded-xl bg-amber-50 text-amber-600"><CheckCircle2 className="size-6" /></div>
          <div>
            <span className="text-sm text-[#64748B]">Tài xế & Bảo mẫu</span>
            <h2 className="text-xl font-bold">{stats.drivers}</h2>
          </div>
        </div>
        <div className="flex items-center gap-4 rounded-2xl bg-white p-5 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
          <div className="grid size-12 place-items-center rounded-xl bg-rose-50 text-rose-600"><ShieldAlert className="size-6" /></div>
          <div>
            <span className="text-sm text-[#64748B]">Cảnh báo mở</span>
            <h2 className="text-xl font-bold">{stats.alerts}</h2>
          </div>
        </div>
      </div>
    </div>
  )
}

// Trang Giám sát đội xe
export function FleetPage() {
  const [buses, setBuses] = useState<any[]>([])

  useEffect(() => {
    supabase.from('buses').select('*').then(({ data }) => setBuses(data ?? []))
  }, [])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Giám sát đội xe</h1>
      <div className="rounded-2xl bg-white p-6 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b text-[#64748B]">
              <th className="pb-3 font-semibold">Biển số xe</th>
              <th className="pb-3 font-semibold">Tài xế</th>
              <th className="pb-3 font-semibold">Trạng thái</th>
              <th className="pb-3 font-semibold">Tuyến đường</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {buses.map((bus) => (
              <tr key={bus.id} className="hover:bg-slate-50">
                <td className="py-3 font-medium">{bus.plate_number}</td>
                <td className="py-3">{bus.driver_name ?? 'Chưa gán'}</td>
                <td className="py-3"><span className="rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700">{bus.status ?? 'Hoạt động'}</span></td>
                <td className="py-3">{bus.route_name ?? 'Đang cập nhật'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// Trang Học sinh & khuôn mặt
export function StudentsPage() {
  const [students, setStudents] = useState<any[]>([])

  useEffect(() => {
    supabase.from('students').select('*').then(({ data }) => setStudents(data ?? []))
  }, [])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Quản lý học sinh & khuôn mặt</h1>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {students.map((student) => (
          <div key={student.id} className="rounded-2xl bg-white p-5 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
            <h3 className="font-bold text-[#0F172A]">{student.full_name}</h3>
            <p className="text-sm text-[#64748B]">Lớp: {student.class_name}</p>
            <span className="mt-3 inline-block rounded-lg bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-600">Đã đăng ký khuôn mặt</span>
          </div>
        ))}
      </div>
    </div>
  )
}

// Trang Tài xế & bảo mẫu
export function StaffPage() {
  const [staffList, setStaffList] = useState<any[]>([])

  useEffect(() => {
    supabase.from('staff').select('*').then(({ data }) => setStaffList(data ?? []))
  }, [])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Tài xế & Bảo mẫu</h1>
      <div className="rounded-2xl bg-white p-6 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b text-[#64748B]">
              <th className="pb-3 font-semibold">Họ tên</th>
              <th className="pb-3 font-semibold">Vai trò</th>
              <th className="pb-3 font-semibold">Số điện thoại</th>
              <th className="pb-3 font-semibold">Trạng thái</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {staffList.map((staff) => (
              <tr key={staff.id} className="hover:bg-slate-50">
                <td className="py-3 font-medium">{staff.full_name}</td>
                <td className="py-3">{staff.role === 'DRIVER' ? 'Tài xế' : 'Bảo mẫu'}</td>
                <td className="py-3">{staff.phone}</td>
                <td className="py-3"><span className="text-emerald-600 font-semibold">Đang làm việc</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// Trang Xe & tuyến đường
export function RoutesPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Xe & Tuyến đường</h1>
      <p className="text-sm text-[#64748B]">Quản lý lộ trình, điểm dừng và phân bổ xe cho từng tuyến.</p>
    </div>
  )
}

// Trang Điểm danh
export function AttendancePage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Điểm danh học sinh</h1>
      <p className="text-sm text-[#64748B]">Nhật ký điểm danh tự động bằng nhận diện khuôn mặt AI trên xe.</p>
    </div>
  )
}

// Trang Đơn xin nghỉ
export function AbsencesPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Đơn xin nghỉ đưa đón</h1>
      <p className="text-sm text-[#64748B]">Phê duyệt hoặc từ chối các đơn xin nghỉ của học sinh.</p>
    </div>
  )
}

// Trang Cảnh báo
export function AlertsPage() {
  const [alerts, setAlerts] = useState<any[]>([])

  useEffect(() => {
    supabase.from('alerts').select('*').in('status', ['OPEN', 'PROCESSING']).then(({ data }) => setAlerts(data ?? []))
  }, [])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Cảnh báo hệ thống</h1>
      <div className="space-y-3">
        {alerts.map((alert) => (
          <div key={alert.id} className="flex items-center justify-between rounded-2xl bg-white p-4 shadow-[0_2px_10px_-4px_rgba(15,23,42,0.06)]">
            <div>
              <h3 className="font-bold text-rose-600">{alert.title}</h3>
              <p className="text-sm text-[#64748B]">{alert.description}</p>
            </div>
            <span className="rounded-full bg-rose-100 px-3 py-1 text-xs font-bold text-rose-700">{alert.status}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

// ==========================================
// 3. ROUTER CONFIGURATION & ROOT APP
// ==========================================
const router = createBrowserRouter([
  {
    element: <AppShell />,
    children: [
      { path: '/', element: <OverviewPage /> },
      { path: '/fleet', element: <FleetPage /> },
      { path: '/students', element: <StudentsPage /> },
      { path: '/staff', element: <StaffPage /> },
      { path: '/routes', element: <RoutesPage /> },
      { path: '/attendance', element: <AttendancePage /> },
      { path: '/absences', element: <AbsencesPage /> },
      { path: '/alerts', element: <AlertsPage /> },
    ],
  },
])

export default function App() {
  return <RouterProvider router={router} />
}