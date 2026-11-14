import {
  Activity,
  AlertTriangle,
  Bus,
  Check,
  MapPin,
  RefreshCw,
  ScanFace,
  Users,
  UserRoundCheck,
  X,
} from 'lucide-react'
import { useOverview } from './hooks/useOverview'
import type { BusLocation } from './types/types'

function formatTime(value: string) {
  return new Date(value).toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

function formatDate(value: string) {
  return new Date(`${value}T00:00:00`).toLocaleDateString('vi-VN', {
    day: '2-digit',
    month: '2-digit',
  })
}

export function OverviewPage() {
  const {
    stats,
    alerts,
    absences,
    attendanceChart,
    aiPercent,
    locations,
    loading,
    error,
    processingId,
    refresh,
    reviewAbsence,
  } = useOverview()

  const cards = [
    {
      label: 'Xe đang chạy',
      value: stats.buses,
      icon: Bus,
      color: 'bg-blue-50 text-blue-600',
      note: 'Số xe có chuyến đang hoạt động hôm nay',
    },
    {
      label: 'Học sinh trên xe',
      value: stats.onboard,
      icon: Users,
      color: 'bg-amber-50 text-amber-600',
      note: `${stats.students} học sinh đang hoạt động`,
    },
    {
      label: 'Tài xế & giáo viên',
      value: stats.staff,
      icon: UserRoundCheck,
      color: 'bg-emerald-50 text-emerald-600',
      note: 'Nhân sự có tài khoản đang hoạt động',
    },
    {
      label: 'Cảnh báo đang mở',
      value: stats.alerts,
      icon: AlertTriangle,
      color: 'bg-rose-50 text-rose-600',
      note: 'Cảnh báo cần được kiểm tra',
    },
  ]

  const minLat = locations.length ? Math.min(...locations.map((item) => item.latitude)) : 0
  const maxLat = locations.length ? Math.max(...locations.map((item) => item.latitude)) : 1
  const minLng = locations.length ? Math.min(...locations.map((item) => item.longitude)) : 0
  const maxLng = locations.length ? Math.max(...locations.map((item) => item.longitude)) : 1

  function markerPosition(item: BusLocation) {
    const x = maxLng === minLng ? 50 : 12 + ((item.longitude - minLng) / (maxLng - minLng)) * 76
    const y = maxLat === minLat ? 50 : 15 + ((maxLat - item.latitude) / (maxLat - minLat)) * 70
    return { left: `${x}%`, top: `${y}%` }
  }

  return (
    <div className="space-y-3.5 pb-5">
      <section className="relative flex min-h-[112px] items-center justify-between overflow-hidden rounded-2xl bg-[#2451D9] px-5 py-4 text-white shadow-sm">
        <div className="relative z-10">
          <h1 className="text-xl font-bold">Tổng quan hệ thống Bus An Toàn</h1>
          <p className="mt-1 text-xs text-blue-100">
            Hôm nay có {stats.buses} xe đang chạy và {stats.alerts} cảnh báo cần xử lý.
          </p>
          <button
            type="button"
            onClick={() => document.getElementById('recent-alerts')?.scrollIntoView({ behavior: 'smooth' })}
            className="mt-3 inline-flex items-center gap-2 rounded-lg bg-[#FFC83D] px-3 py-1.5 text-xs font-bold text-slate-900"
          >
            <AlertTriangle className="size-3.5" />
            Xem cảnh báo
          </button>
        </div>
        <div className="pointer-events-none absolute -right-2 -top-16 size-48 rounded-full bg-[#183DB3] opacity-70" />
        <div className="relative z-10 mr-5 hidden sm:block">
          <Bus className="size-20 text-amber-300" />
        </div>
      </section>

      {error && (
        <div className="flex items-center justify-between rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-600">
          <span>{error}</span>
          <button type="button" onClick={() => void refresh()} aria-label="Thử tải lại">
            <RefreshCw className="size-4" />
          </button>
        </div>
      )}

      <section className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        {cards.map((card) => {
          const Icon = card.icon
          return (
            <div key={card.label} className="rounded-2xl border border-slate-100 bg-white p-3.5 shadow-sm">
              <div className="flex items-center gap-3">
                <div className={`grid size-10 shrink-0 place-items-center rounded-xl ${card.color}`}>
                  <Icon className="size-5" />
                </div>
                <div className="min-w-0">
                  <p className="truncate text-[11px] font-medium text-slate-500">{card.label}</p>
                  <h2 className="text-xl font-bold text-[#142957]">
                    {loading ? '...' : card.value.toLocaleString('vi-VN')}
                  </h2>
                </div>
              </div>
              <p className="mt-2 border-t border-slate-100 pt-2 text-[10px] text-slate-400">{card.note}</p>
            </div>
          )
        })}
      </section>

      <section className="grid grid-cols-1 gap-3 xl:grid-cols-[1.55fr_0.9fr]">
        <div className="rounded-2xl border border-slate-100 bg-white p-3.5 shadow-sm">
          <div className="mb-3 flex items-center justify-between">
            <div>
              <h2 className="text-sm font-bold text-[#142957]">Bản đồ đội xe trực tiếp</h2>
              <p className="text-[10px] text-slate-400">Vị trí GPS mới nhất của các chuyến đang chạy</p>
            </div>
            <span className="rounded-full bg-emerald-50 px-2 py-1 text-[9px] font-bold text-emerald-600">
              {locations.length} xe có GPS
            </span>
          </div>
          <div className="relative h-[190px] overflow-hidden rounded-xl bg-[#F5F2E5]">
            <svg viewBox="0 0 600 220" preserveAspectRatio="none" className="absolute inset-0 size-full">
              <rect width="600" height="220" fill="#F5F2E5" />
              <path d="M0 85 Q130 125 250 80 T600 105" fill="none" stroke="#B7DCF3" strokeWidth="32" />
              <path d="M-20 20 L620 30 M-20 150 L620 140 M80 -20 L100 250 M290 -20 L260 250 M490 -20 L465 250" fill="none" stroke="#FFFFFF" strokeWidth="9" />
            </svg>
            {locations.map((item) => (
              <div
                key={item.trip_id}
                title={`${item.license_plate} - ${item.speed ?? 0} km/h`}
                className="absolute z-10 -translate-x-1/2 -translate-y-1/2"
                style={markerPosition(item)}
              >
                <div className="grid size-7 place-items-center rounded-full border-2 border-white bg-amber-400 text-white shadow-md">
                  <Bus className="size-4" />
                </div>
                <span className="absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded bg-white px-1.5 py-0.5 text-[9px] font-bold text-slate-700 shadow">
                  {item.license_plate}
                </span>
              </div>
            ))}
            {locations.length === 0 && (
              <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                <MapPin className="mb-2 size-7 text-slate-400" />
                <p className="text-xs font-semibold text-slate-600">Chưa có dữ liệu GPS</p>
                <p className="mt-1 text-[10px] text-slate-400">Cần có chuyến IN_PROGRESS và bản ghi GPS</p>
              </div>
            )}
            <div className="absolute bottom-2 left-2 rounded-lg bg-white/95 px-2.5 py-1.5 text-[9px] text-slate-600 shadow">
              <span className="mr-1 text-amber-500">●</span> Vị trí xe từ GPS
            </div>
          </div>
        </div>

        <div id="recent-alerts" className="rounded-2xl border border-slate-100 bg-white p-3.5 shadow-sm">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-bold text-[#142957]">Cảnh báo gần đây</h2>
            <span className="text-[10px] font-semibold text-blue-600">{stats.alerts} cảnh báo</span>
          </div>
          <div className="space-y-2">
            {loading ? (
              <p className="py-8 text-center text-xs text-slate-400">Đang tải cảnh báo...</p>
            ) : alerts.length ? (
              alerts.map((alert) => (
                <div key={alert.alert_id} className="flex gap-2.5 rounded-xl bg-[#F5F8FF] p-2.5">
                  <div className="grid size-7 shrink-0 place-items-center rounded-lg bg-rose-100 text-rose-600">
                    <AlertTriangle className="size-3.5" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[11px] font-bold text-[#142957]">{alert.title}</p>
                    <p className="mt-0.5 line-clamp-2 text-[10px] leading-4 text-slate-500">{alert.message}</p>
                    <span className="text-[9px] text-rose-500">{alert.severity}</span>
                  </div>
                  <span className="shrink-0 text-[9px] text-slate-400">{formatTime(alert.created_at)}</span>
                </div>
              ))
            ) : (
              <div className="flex min-h-[130px] flex-col items-center justify-center">
                <Check className="mb-2 size-8 rounded-full bg-emerald-50 p-2 text-emerald-600" />
                <p className="text-xs text-slate-500">Không có cảnh báo mới</p>
              </div>
            )}
          </div>
        </div>
      </section>

      <section className="grid grid-cols-1 gap-3 lg:grid-cols-2 xl:grid-cols-[1.1fr_0.9fr_0.95fr]">
        <div className="rounded-2xl border border-slate-100 bg-white p-3.5 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-sm font-bold text-[#142957]">Điểm danh theo ngày</h2>
            <span className="rounded-full bg-blue-50 px-2 py-1 text-[9px] font-semibold text-blue-600">Lượt check-in</span>
          </div>
          <div className="flex h-[135px] items-end justify-around gap-2 border-b border-slate-100 px-1">
            {attendanceChart.map((item, index) => {
              const maxValue = Math.max(...attendanceChart.map((row) => row.value), 1)
              return (
                <div key={item.day} className="flex h-full flex-1 flex-col items-center justify-end">
                  <span className="mb-1 text-[9px] font-semibold text-slate-500">{item.value}</span>
                  <div
                    className={`w-full max-w-[27px] rounded-t-md ${index === 5 ? 'bg-amber-400' : 'bg-blue-600'}`}
                    style={{ height: `${Math.max(3, (item.value / maxValue) * 95)}px` }}
                  />
                  <span className="mt-2 whitespace-nowrap text-[8px] text-slate-400">{item.day}</span>
                </div>
              )
            })}
          </div>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-3.5 shadow-sm">
          <h2 className="mb-4 text-sm font-bold text-[#142957]">Cách điểm danh hôm nay</h2>
          <div className="flex items-center justify-center gap-5 py-3">
            <div
              className="relative grid size-[104px] shrink-0 place-items-center rounded-full"
              style={{ background: `conic-gradient(#2864F6 0% ${aiPercent}%, #FFC83D ${aiPercent}% 100%)` }}
            >
              <div className="grid size-[82px] place-items-center rounded-full bg-white">
                <span className="text-2xl font-bold text-[#142957]">{aiPercent}%</span>
              </div>
            </div>
            <div className="space-y-3">
              <div>
                <div className="flex items-center gap-2">
                  <span className="size-2 rounded-full bg-blue-600" />
                  <span className="text-[10px] text-slate-600">Nhận diện AI</span>
                </div>
                <p className="ml-4 text-sm font-bold text-[#142957]">{aiPercent}%</p>
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="size-2 rounded-full bg-amber-400" />
                  <span className="text-[10px] text-slate-600">Thủ công</span>
                </div>
                <p className="ml-4 text-sm font-bold text-[#142957]">{100 - aiPercent}%</p>
              </div>
            </div>
          </div>
          <div className="mt-2 rounded-lg bg-blue-50 px-2 py-2 text-center text-[10px] text-blue-700">
            <ScanFace className="mr-1 inline size-3.5" />
            Dữ liệu từ bảng attendance
          </div>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-3.5 shadow-sm">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-bold text-[#142957]">Đơn xin nghỉ chờ duyệt</h2>
            <span className="rounded-full bg-amber-100 px-2 py-1 text-[9px] font-bold text-amber-700">
              {absences.length} đơn
            </span>
          </div>
          <div className="space-y-2.5">
            {absences.map((item) => (
              <div key={item.absence_id} className="flex items-center gap-2">
                <div className="grid size-8 shrink-0 place-items-center rounded-full bg-blue-100 text-[10px] font-bold text-blue-700">
                  {item.student_name.charAt(0) || '?'}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[10px] font-bold text-[#142957]">
                    {item.student_name}{item.class_name ? ` · ${item.class_name}` : ''}
                  </p>
                  <p className="text-[9px] text-slate-400">
                    {formatDate(item.absence_date)} · {item.session === 'MORNING' ? 'Buổi sáng' : 'Buổi chiều'}
                  </p>
                </div>
                <button
                  type="button"
                  disabled={processingId === item.absence_id}
                  onClick={() => void reviewAbsence(item.absence_id, 'APPROVED')}
                  title="Duyệt đơn"
                  className="grid size-7 shrink-0 place-items-center rounded-lg bg-emerald-100 text-emerald-700 hover:bg-emerald-200 disabled:opacity-50"
                >
                  {processingId === item.absence_id
                    ? <RefreshCw className="size-3 animate-spin" />
                    : <Check className="size-3.5" />}
                </button>
                <button
                  type="button"
                  disabled={processingId === item.absence_id}
                  onClick={() => void reviewAbsence(item.absence_id, 'REJECTED')}
                  title="Từ chối đơn"
                  className="grid size-7 shrink-0 place-items-center rounded-lg bg-rose-100 text-rose-600 hover:bg-rose-200 disabled:opacity-50"
                >
                  <X className="size-3.5" />
                </button>
              </div>
            ))}
            {!loading && absences.length === 0 && (
              <div className="py-8 text-center">
                <Check className="mx-auto mb-2 size-8 text-emerald-500" />
                <p className="text-xs text-slate-500">Không có đơn xin nghỉ chờ duyệt</p>
              </div>
            )}
            {loading && <p className="py-8 text-center text-xs text-slate-400">Đang tải đơn xin nghỉ...</p>}
          </div>
          <div className="mt-3 border-t border-slate-100 pt-3 text-center text-[10px] text-slate-400">
            Dữ liệu từ bảng absences và students
          </div>
        </div>
      </section>

      <div className="flex flex-wrap items-center justify-between gap-2 px-1 pt-1 text-[10px] text-slate-400">
        <span className="flex items-center gap-1.5">
          <Activity className="size-3.5 text-emerald-500" />
          Hệ thống quản lý Bus An Toàn
        </span>
        <button
          type="button"
          onClick={() => void refresh()}
          disabled={loading}
          className="flex items-center gap-1.5 hover:text-blue-600 disabled:opacity-50"
        >
          <RefreshCw className={`size-3 ${loading ? 'animate-spin' : ''}`} />
          Cập nhật dữ liệu
        </button>
      </div>
    </div>
  )
}

export default OverviewPage
