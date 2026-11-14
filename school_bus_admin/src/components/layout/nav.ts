import {
  CalendarX,
  ClipboardCheck,
  Contact,
  LayoutDashboard,
  MapPin,
  Route,
  TriangleAlert,
  Users,
  type LucideIcon,
} from 'lucide-react'

export interface NavItem {
  to: string
  label: string
  icon: LucideIcon
  end?: boolean
  badge?: 'absences' | 'alerts'
}

/** Thứ tự và tên mục theo thanh bên trong Figma. */
export const NAV: NavItem[] = [
  { to: '/', label: 'Tổng quan', icon: LayoutDashboard, end: true },
  { to: '/monitor', label: 'Giám sát đội xe', icon: MapPin },
  { to: '/students', label: 'Học sinh & khuôn mặt', icon: Users },
  { to: '/staff', label: 'Tài xế & bảo mẫu', icon: Contact },
  { to: '/fleet', label: 'Xe & tuyến đường', icon: Route },
  { to: '/attendance', label: 'Điểm danh', icon: ClipboardCheck },
  { to: '/absences', label: 'Đơn xin nghỉ', icon: CalendarX, badge: 'absences' },
  { to: '/alerts', label: 'Cảnh báo', icon: TriangleAlert, badge: 'alerts' },
]

export const PAGE_TITLES: Record<string, string> = {
  ...Object.fromEntries(NAV.map((n) => [n.to, n.label])),
  '/account': 'Tài khoản & bảo mật',
}

