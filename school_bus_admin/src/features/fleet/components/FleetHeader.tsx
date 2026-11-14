
import { RefreshCw } from 'lucide-react'

interface FleetHeaderProps {
  total: number
  onRefresh: () => void
  isRefreshing: boolean
}

export function FleetHeader({
  total,
  onRefresh,
  isRefreshing,
}: FleetHeaderProps) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">
          Giám sát đội xe
        </h1>

        <p className="mt-1 text-sm text-slate-500">
          {total} xe trong hệ thống · Theo dõi hoạt động đội xe
        </p>
      </div>

      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={onRefresh}
          title="Làm mới dữ liệu"
          className="grid size-10 place-items-center rounded-xl border border-slate-200 bg-white text-slate-600 hover:bg-slate-50"
        >
          <RefreshCw
            className={`size-4 ${isRefreshing ? 'animate-spin' : ''}`}
          />
        </button>
      </div>
    </div>
  )
}
