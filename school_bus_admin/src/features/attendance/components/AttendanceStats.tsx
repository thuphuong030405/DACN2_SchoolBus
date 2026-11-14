import { Users, Check, Clock, Calendar } from 'lucide-react'
import type { AttendanceSummary } from '../types'

interface AttendanceStatsProps {
  summary: AttendanceSummary
}

export function AttendanceStats({ summary }: AttendanceStatsProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {/* KPI 1: Dự kiến hôm nay */}
      <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
        <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-blue-50 text-blue-600">
          <Users className="size-6" />
        </div>
        <div>
          <p className="text-xs font-medium text-slate-500">Dự kiến hôm nay</p>
          <p className="my-0.5 text-2xl font-extrabold text-slate-900">
            {summary.expected_today}
          </p>
          <span className="inline-block rounded-full bg-blue-100 px-2.5 py-0.5 text-[11px] font-semibold text-blue-700">
            Cả đón và trả
          </span>
        </div>
      </div>

      {/* KPI 2: Đã lên xe */}
      <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
        <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-emerald-50 text-emerald-600">
          <Check className="size-6" />
        </div>
        <div>
          <p className="text-xs font-medium text-slate-500">Đã lên xe</p>
          <p className="my-0.5 text-2xl font-extrabold text-slate-900">
            {summary.boarded_today}
          </p>
          <span className="inline-block rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-semibold text-emerald-700">
            {summary.ai_rate}% bằng AI
          </span>
        </div>
      </div>

      {/* KPI 3: Chưa lên xe */}
      <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
        <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-amber-50 text-amber-500">
          <Clock className="size-6" />
        </div>
        <div>
          <p className="text-xs font-medium text-slate-500">Chưa lên xe</p>
          <p className="my-0.5 text-2xl font-extrabold text-slate-900">
            {summary.pending_today}
          </p>
          <span className="inline-block rounded-full bg-amber-100 px-2.5 py-0.5 text-[11px] font-semibold text-amber-700">
            Đang chờ đón
          </span>
        </div>
      </div>

      {/* KPI 4: Nghỉ có phép */}
      <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
        <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-slate-100 text-slate-500">
          <Calendar className="size-6" />
        </div>
        <div>
          <p className="text-xs font-medium text-slate-500">Nghỉ có phép</p>
          <p className="my-0.5 text-2xl font-extrabold text-slate-900">
            {summary.absent_today}
          </p>
          <span className="inline-block rounded-full bg-slate-100 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600">
            Đã duyệt
          </span>
        </div>
      </div>
    </div>
  )
}