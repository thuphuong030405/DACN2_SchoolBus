
import { Bus } from 'lucide-react'

import type {
  BusItem,
  FilterType,
  FleetCounts,
} from '../types/fleet.types'

import { filters } from '../types/fleet.types'
import { VehicleCard } from './VehicleCard'

interface VehicleListProps {
  buses: BusItem[]
  selectedBusId: string | null
  filter: FilterType
  counts: FleetCounts
  isLoading: boolean
  error: Error | null
  onFilterChange: (filter: FilterType) => void
  onSelectBus: (busId: string) => void
}

export function VehicleList({
  buses,
  selectedBusId,
  filter,
  counts,
  isLoading,
  error,
  onFilterChange,
  onSelectBus,
}: VehicleListProps) {
  const getCount = (value: FilterType) => {
    switch (value) {
      case 'ALL':
        return counts.all
      case 'ACTIVE':
        return counts.active
      case 'MAINTENANCE':
        return counts.warning
      case 'INACTIVE':
        return counts.inactive
    }
  }

  return (
    <section className="flex flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      {/* FILTER HEADER */}
      <div className="border-b border-slate-100 p-4">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="font-bold text-slate-800">
            Danh sách xe
          </h2>

          <span className="text-xs text-slate-400">
            {buses.length} xe
          </span>
        </div>

        <div className="grid grid-cols-4 gap-1.5">
          {filters.map((item) => {
            const active = filter === item.value

            return (
              <button
                key={item.value}
                type="button"
                onClick={() => onFilterChange(item.value)}
                className={`rounded-xl px-1 py-2 text-center transition ${
                  active
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100'
                }`}
              >
                <span className="block text-xs font-semibold">
                  {item.label}
                </span>

                <span className="mt-0.5 block text-sm font-bold">
                  {getCount(item.value)}
                </span>
              </button>
            )
          })}
        </div>
      </div>

      {/* VEHICLE CARDS */}
      <div className="flex-1 space-y-2 overflow-y-auto bg-slate-50/60 p-3">
        {isLoading && (
          <p className="py-10 text-center text-sm text-slate-500">
            Đang tải danh sách xe...
          </p>
        )}

        {error && (
          <p className="rounded-xl bg-red-50 p-3 text-sm text-red-600">
            Không thể tải dữ liệu: {error.message}
          </p>
        )}

        {!isLoading &&
          !error &&
          buses.map((bus) => (
            <VehicleCard
              key={bus.bus_id}
              bus={bus}
              selected={selectedBusId === bus.bus_id}
              onClick={() => onSelectBus(bus.bus_id)}
            />
          ))}

        {!isLoading && !error && buses.length === 0 && (
          <div className="py-12 text-center">
            <Bus className="mx-auto mb-2 size-8 text-slate-300" />

            <p className="text-sm text-slate-500">
              Không tìm thấy xe phù hợp
            </p>
          </div>
        )}
      </div>
    </section>
  )
}
