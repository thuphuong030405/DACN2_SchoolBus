
import type { FleetCounts } from '../types/fleet.types'

interface FleetStatsProps {
  counts: FleetCounts
}

export function FleetStats({ counts }: FleetStatsProps) {
  const items = [
    {
      label: 'Tổng số xe',
      value: counts.all,
      color: 'text-slate-800',
    },
    {
      label: 'Đang hoạt động',
      value: counts.active,
      color: 'text-blue-600',
    },
    {
      label: 'Cảnh báo',
      value: counts.warning,
      color: 'text-red-600',
    },
    {
      label: 'Ngừng hoạt động',
      value: counts.inactive,
      color: 'text-slate-500',
    },
  ]

  return (
    <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
      {items.map((item) => (
        <div
          key={item.label}
          className="rounded-xl border border-slate-200 bg-white p-4"
        >
          <p className="text-xs text-slate-500">{item.label}</p>
          <p className={`mt-2 text-2xl font-bold ${item.color}`}>
            {item.value}
          </p>
        </div>
      ))}
    </div>
  )
}
