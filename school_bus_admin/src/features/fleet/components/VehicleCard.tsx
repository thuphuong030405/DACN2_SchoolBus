
import { ChevronRight } from 'lucide-react'

import type { BusItem } from '../types/fleet.types'
import {
  normalizeBusStatus,
  statusConfig,
} from '../types/fleet.types'

interface VehicleCardProps {
  bus: BusItem
  selected: boolean
  onClick: () => void
}

export function VehicleCard({
  bus,
  selected,
  onClick,
}: VehicleCardProps) {
  const status = normalizeBusStatus(bus.status)
  const config = statusConfig[status]

  return (
    <button
      type="button"
      onClick={onClick}
      className={`w-full rounded-2xl border bg-white p-3 text-left transition-all ${
        selected
          ? 'border-blue-500 ring-2 ring-blue-100 shadow-sm'
          : status === 'MAINTENANCE'
            ? 'border-red-300 hover:border-red-400'
            : 'border-slate-100 hover:border-blue-300'
      }`}
    >
      <div className="mb-2 flex items-center justify-between gap-2">
        <span className="text-sm font-bold text-slate-800">
          {bus.license_plate}
        </span>

        <span
          className={`rounded-full px-2 py-1 text-[10px] font-semibold ${config.className}`}
        >
          {config.label}
        </span>
      </div>

      <p className="text-xs text-slate-500">
        {bus.bus_code} · {bus.vehicle_model || 'Chưa cập nhật dòng xe'}
      </p>

      <div className="mt-3 flex items-center justify-between">
        <span className="text-xs text-slate-500">Sức chứa</span>

        <span className="text-xs font-bold text-slate-700">
          {bus.capacity} chỗ
        </span>
      </div>

      <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-slate-100">
        <div
          className={`h-full rounded-full ${
            status === 'MAINTENANCE'
              ? 'bg-red-400'
              : status === 'ACTIVE'
                ? 'bg-blue-500'
                : 'bg-slate-300'
          }`}
          style={{
            width: status === 'ACTIVE' ? '75%' : '0%',
          }}
        />
      </div>

      <div className="mt-2 flex items-center justify-between">
        <span className="text-[11px] text-slate-400">
          Mã xe: {bus.bus_code}
        </span>

        <ChevronRight className="size-4 text-slate-400" />
      </div>
    </button>
  )
}

export default VehicleCard
