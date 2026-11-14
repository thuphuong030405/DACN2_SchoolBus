import { ShieldCheck } from 'lucide-react'
import type { RouteProgressItem, TripOption } from '../types'

interface AttendanceSidebarProps {
  selectedTrip: TripOption | null
  boardedCount: number
  alightedCount: number
  onBusCount: number
  routeProgress: RouteProgressItem[]
  isCompleting: boolean
  onCompleteTrip: () => void
}

export function AttendanceSidebar({
  selectedTrip,
  boardedCount,
  alightedCount,
  onBusCount,
  routeProgress,
  isCompleting,
  onCompleteTrip,
}: AttendanceSidebarProps) {
  const isCompleted = selectedTrip?.status === 'COMPLETED'

  return (
    <aside className="flex flex-col gap-5">
      {/* Card 1: Đối soát sĩ số */}
      <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-bold text-slate-900">
            Đối soát sĩ số
          </h2>

          {isCompleted ? (
            <span className="rounded-full bg-emerald-100 px-2.5 py-1 text-[11px] font-semibold text-emerald-700">
              Đã chốt chuyến
            </span>
          ) : (
            <span className="rounded-full bg-amber-100 px-2.5 py-1 text-[11px] font-semibold text-amber-700">
              Chưa chốt chuyến
            </span>
          )}
        </div>

        <div className="mb-4 grid grid-cols-3 gap-2">
          <div className="rounded-xl bg-blue-50/90 px-2 py-3.5 text-center">
            <p className="text-xl font-extrabold text-slate-900">
              {boardedCount}
            </p>
            <p className="mt-0.5 text-[11px] font-medium text-slate-600">
              Lượt lên xe
            </p>
          </div>

          <div className="rounded-xl bg-amber-50/90 px-2 py-3.5 text-center">
            <p className="text-xl font-extrabold text-slate-900">
              {alightedCount}
            </p>
            <p className="mt-0.5 text-[11px] font-medium text-slate-600">
              Lượt xuống xe
            </p>
          </div>

          <div className="rounded-xl bg-rose-50/90 px-2 py-3.5 text-center">
            <p className="text-xl font-extrabold text-slate-900">
              {onBusCount}
            </p>
            <p className="mt-0.5 text-[11px] font-medium text-slate-600">
              Còn trên xe
            </p>
          </div>
        </div>

        <div className="mb-4 rounded-xl bg-slate-50 p-3.5 text-xs leading-relaxed text-slate-500">
          Chỉ chốt được chuyến khi số lượt lên bằng số lượt xuống. Nếu còn học
          sinh trên xe, hệ thống tự bật còi báo động và gửi cảnh báo cho cô
          giáo, tài xế và nhà trường.
        </div>

        <button
          type="button"
          onClick={onCompleteTrip}
          disabled={!selectedTrip || isCompleted || isCompleting}
          className={`inline-flex w-full items-center justify-center gap-2 rounded-xl border px-4 py-2.5 text-xs font-bold transition ${
            onBusCount === 0 && !isCompleted
              ? 'border-blue-600 bg-blue-600 text-white hover:bg-blue-700'
              : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
          } disabled:opacity-60`}
        >
          <ShieldCheck className="size-4" />
          {isCompleted ? 'Đã chốt chuyến' : 'Chốt chuyến'}
        </button>
      </div>

      {/* Card 2: Theo tuyến · hôm nay */}
      <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
        <h2 className="mb-4 text-base font-bold text-slate-900">
          Theo tuyến · hôm nay
        </h2>

        <div className="space-y-3.5">
          {routeProgress.length === 0 && (
            <p className="text-xs text-slate-400">Chưa có dữ liệu tuyến</p>
          )}

          {routeProgress.map((item) => {
            const percent =
              item.total_count > 0
                ? Math.min(
                    100,
                    Math.round((item.boarded_count / item.total_count) * 100)
                  )
                : 0

            return (
              <div
                key={item.route_id}
                className="flex items-center gap-3 text-xs"
              >
                <span className="w-20 shrink-0 truncate font-semibold text-slate-700">
                  {item.route_name}
                </span>

                <div className="h-2 flex-1 overflow-hidden rounded-full bg-slate-100">
                  <div
                    className="h-full rounded-full bg-blue-600 transition-all duration-300"
                    style={{ width: `${percent}%` }}
                  />
                </div>

                <span className="w-11 shrink-0 text-right font-semibold text-slate-600">
                  {item.boarded_count}/{item.total_count}
                </span>
              </div>
            )
          })}
        </div>
      </div>
    </aside>
  )
}