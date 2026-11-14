import { useState } from 'react'
import { Check, ChevronDown } from 'lucide-react'
import type { StudentAttendanceRow, TripOption } from '../types'

export type FilterTab = 'ALL' | 'BOARDED' | 'PENDING' | 'ABSENT'

interface AttendanceTableProps {
  trips: TripOption[]
  selectedTrip: TripOption | null
  onSelectTrip: (tripId: string) => void
  rows: StudentAttendanceRow[]
  isLoading: boolean
  activeTab: FilterTab
  onTabChange: (tab: FilterTab) => void
  stats: {
    total: number
    boardedCount: number
    pendingCount: number
    absentCount: number
    progressPercent: number
  }
  isCheckingIn: boolean
  onManualCheckIn: (row: StudentAttendanceRow) => void
}

const avatarPalette = [
  'bg-blue-100 text-blue-700',
  'bg-amber-100 text-amber-700',
  'bg-emerald-100 text-emerald-700',
  'bg-rose-100 text-rose-700',
]

function getInitials(fullName: string): string {
  const parts = fullName.trim().split(/\s+/)
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
  return (parts[parts.length - 2][0] + parts[parts.length - 1][0]).toUpperCase()
}

function formatTimeHHMM(isoStr: string | null): string {
  if (!isoStr) return '—'
  return new Date(isoStr).toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: 'Asia/Ho_Chi_Minh',
  })
}

export function AttendanceTable({
  trips,
  selectedTrip,
  onSelectTrip,
  rows,
  isLoading,
  activeTab,
  onTabChange,
  stats,
  isCheckingIn,
  onManualCheckIn,
}: AttendanceTableProps) {
  const [isTripMenuOpen, setIsTripMenuOpen] = useState(false)

  const tripTitle = selectedTrip
    ? `${selectedTrip.trip_type === 'MORNING' ? 'Chuyến đón sáng' : 'Chuyến trả chiều'} · ${selectedTrip.route_name} · ${selectedTrip.bus_plate}`
    : 'Chưa có chuyến xe nào'

  return (
    <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
      {/* Header & Dropdown đổi chuyến */}
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-base font-bold text-slate-900">{tripTitle}</h2>

        <div className="relative">
          <button
            type="button"
            onClick={() => setIsTripMenuOpen((prev) => !prev)}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50"
          >
            <ChevronDown className="size-4 text-slate-500" />
            Đổi chuyến
          </button>

          {isTripMenuOpen && (
            <div className="absolute right-0 z-20 mt-1.5 w-72 rounded-xl border border-slate-200 bg-white p-1.5 shadow-lg">
              {trips.length === 0 ? (
                <p className="px-3 py-2 text-xs text-slate-400">
                  Không có chuyến nào
                </p>
              ) : (
                trips.map((t) => (
                  <button
                    key={t.trip_id}
                    type="button"
                    onClick={() => {
                      onSelectTrip(t.trip_id)
                      setIsTripMenuOpen(false)
                    }}
                    className={`flex w-full flex-col rounded-lg px-3 py-2 text-left text-xs transition ${
                      t.trip_id === selectedTrip?.trip_id
                        ? 'bg-blue-50 font-bold text-blue-700'
                        : 'text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    <span>
                      {t.trip_type === 'MORNING' ? 'Đón sáng' : 'Trả chiều'} ·{' '}
                      {t.route_name}
                    </span>
                    <span className="text-[11px] font-normal text-slate-400">
                      Xe {t.bus_plate} · Ngày {t.trip_date}
                    </span>
                  </button>
                ))
              )}
            </div>
          )}
        </div>
      </div>

      {/* Filter Pills */}
      <div className="mb-4 flex flex-wrap items-center gap-2">
        {[
          { key: 'ALL', label: `Tất cả ${stats.total}` },
          { key: 'BOARDED', label: `Đã lên ${stats.boardedCount}` },
          { key: 'PENDING', label: `Chưa lên ${stats.pendingCount}` },
          { key: 'ABSENT', label: `Nghỉ ${stats.absentCount}` },
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => onTabChange(tab.key as FilterTab)}
            className={`rounded-full px-4 py-1.5 text-xs font-semibold transition ${
              activeTab === tab.key
                ? 'bg-blue-600 text-white shadow-xs'
                : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Progress Bar */}
      <div className="mb-5 flex items-center gap-4">
        <div className="h-2 flex-1 overflow-hidden rounded-full bg-slate-100">
          <div
            className="h-full rounded-full bg-blue-600 transition-all duration-300"
            style={{ width: `${stats.progressPercent}%` }}
          />
        </div>
        <span className="shrink-0 text-xs font-bold text-slate-800">
          {stats.boardedCount} / {stats.total} đã lên xe
        </span>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left">
          <thead>
            <tr className="border-b border-slate-100 text-[11px] font-semibold text-slate-400">
              <th className="py-3 pl-2 pr-2">Học sinh</th>
              <th className="px-2 py-3">Điểm đón</th>
              <th className="px-2 py-3">Giờ lên</th>
              <th className="px-2 py-3">Nguồn</th>
              <th className="py-3 pl-2 pr-2">Trạng thái</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-100 text-xs">
            {isLoading && (
              <tr>
                <td colSpan={5} className="py-12 text-center text-slate-400">
                  Đang tải danh sách điểm danh...
                </td>
              </tr>
            )}

            {!isLoading && rows.length === 0 && (
              <tr>
                <td colSpan={5} className="py-12 text-center text-slate-400">
                  Không có học sinh nào trong mục này
                </td>
              </tr>
            )}

            {rows.map((row, idx) => {
              const avatarClass = avatarPalette[idx % avatarPalette.length]
              const isBoarded =
                row.status === 'BOARDED' || row.status === 'ALIGHTED'
              const isManual = row.detection_method === 'MANUAL'

              return (
                <tr
                  key={`${selectedTrip?.trip_id}-${activeTab}-${row.student_id}`}
                  className="transition-colors hover:bg-slate-50/70"
                >
                  <td className="py-3 pl-2 pr-2">
                    <div className="flex items-center gap-3">
                      <div
                        className={`grid size-9 shrink-0 place-items-center rounded-full text-xs font-bold ${avatarClass}`}
                      >
                        {getInitials(row.full_name)}
                      </div>
                      <span className="font-bold text-slate-800">
                        {row.full_name}
                      </span>
                    </div>
                  </td>

                  <td className="px-2 py-3 text-slate-500">
                    {row.pickup_stop_name}
                  </td>

                  <td className="px-2 py-3 font-medium text-slate-700">
                    {formatTimeHHMM(row.check_in_time)}
                  </td>

                  <td className="px-2 py-3 font-semibold text-slate-700">
                    {!isBoarded ? (
                      <span className="font-normal text-slate-400">—</span>
                    ) : isManual ? (
                      'Thủ công'
                    ) : (
                      `AI · ${
                        row.ai_confidence
                          ? Math.round(
                              row.ai_confidence <= 1
                                ? row.ai_confidence * 100
                                : row.ai_confidence
                            )
                          : 95
                      }%`
                    )}
                  </td>

                <td className="py-3 pl-2 pr-2">
                    <div className="flex items-center justify-between gap-2.5">
                      {isBoarded && (
                        <span
                          style={
                            isManual
                              ? {
                                  backgroundColor: '#d2ffc6',
                                  color: '#23640f',
                                }
                              : {
                                  backgroundColor: '#DCFCE7',
                                  color: '#166534',
                                }
                          }
                          className="inline-flex shrink-0 whitespace-nowrap rounded-full px-3.5 py-1 text-[11px] font-bold"
                        >
                          Đã lên xe
                        </span>
                      )}

                      {row.status === 'PENDING' && (
                        <>
                          <span className="inline-flex shrink-0 whitespace-nowrap rounded-full bg-rose-50 px-3 py-1 text-[11px] font-semibold text-rose-600 ring-1 ring-inset ring-rose-200/70">
                            Chưa lên xe
                          </span>

                          <button
                            type="button"
                            disabled={isCheckingIn}
                            onClick={() => onManualCheckIn(row)}
                            style={{
                              backgroundColor: '#feffb3',
                              color: '#713F12',
                              border: '1px solid #faf615',
                            }}
                            className="inline-flex shrink-0 cursor-pointer items-center gap-1.5 whitespace-nowrap rounded-full px-3.5 py-1 text-xs font-bold shadow-2xs transition-all hover:brightness-95 active:scale-[0.98] disabled:opacity-50"
                          >
                            <Check className="size-3.5 stroke-[2.5]" />
                            Điểm danh tay
                          </button>
                        </>
                      )}

                      {row.status === 'ABSENT' && (
                        <span
                          style={{
                            backgroundColor: '#E2E8F0',
                            color: '#334155',
                          }}
                          className="inline-flex shrink-0 whitespace-nowrap rounded-full px-3.5 py-1 text-[11px] font-bold"
                        >
                          Nghỉ có phép
                        </span>
                      )}
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </section>
  )
}