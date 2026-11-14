
import {
  Bus,
  Gauge,
  Navigation,
  Radio,
} from 'lucide-react'

import type {
  BusItem,
  RouteItem,
  RouteStop,
} from '../types/fleet.types'

import {
  normalizeBusStatus,
  statusConfig,
} from '../types/fleet.types'

interface VehicleDetailProps {
  bus: BusItem | null
  route: RouteItem | null
  stops: RouteStop[]
  isLoadingStops: boolean
  stopsError: Error | null
}

export function VehicleDetail({
  bus,
  route,
  stops,
  isLoadingStops,
  stopsError,
}: VehicleDetailProps) {
  const status = bus ? normalizeBusStatus(bus.status) : null
  const config = status ? statusConfig[status] : null

  return (
    <div className="grid grid-cols-1 gap-3 lg:grid-cols-[1.2fr_1fr]">
      {/* VEHICLE INFORMATION */}
      <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h3 className="font-bold text-slate-800">
              {bus?.license_plate ?? 'Chưa chọn xe'}
            </h3>

            <p className="mt-1 text-xs text-slate-400">
              {bus?.bus_code ?? 'Thông tin xe'}
            </p>
          </div>

          {config && (
            <span
              className={`rounded-full px-3 py-1 text-xs font-semibold ${config.className}`}
            >
              {config.label}
            </span>
          )}
        </div>

        <div className="grid grid-cols-3 gap-2">
          <div className="rounded-xl bg-blue-50 p-3">
            <Gauge className="mb-2 size-4 text-blue-600" />

            <p className="text-[10px] text-slate-500">
              Sức chứa
            </p>

            <p className="text-sm font-bold text-slate-800">
              {bus?.capacity ?? '--'} chỗ
            </p>
          </div>

          <div className="rounded-xl bg-blue-50 p-3">
            <Bus className="mb-2 size-4 text-blue-600" />

            <p className="text-[10px] text-slate-500">
              Dòng xe
            </p>

            <p className="truncate text-xs font-bold text-slate-800">
              {bus?.vehicle_model ?? '--'}
            </p>
          </div>

          <div className="rounded-xl bg-blue-50 p-3">
            <Radio className="mb-2 size-4 text-blue-600" />

            <p className="text-[10px] text-slate-500">
              Trạng thái
            </p>

            <p className="text-xs font-bold text-slate-800">
              {config?.label ?? '--'}
            </p>
          </div>
        </div>
      </div>

      {/* ROUTE STOPS */}
      <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="font-bold text-slate-800">
            Lộ trình xe
          </h3>

          <Navigation className="size-4 text-blue-600" />
        </div>

        <p className="mb-3 text-xs text-slate-500">
          {route?.route_name ?? 'Chưa chọn tuyến'}
        </p>

        <div className="max-h-36 space-y-3 overflow-y-auto">
          {isLoadingStops && (
            <p className="text-xs text-slate-400">
              Đang tải điểm dừng...
            </p>
          )}

          {stopsError && (
            <p className="text-xs text-red-500">
              Không tải được điểm dừng: {stopsError.message}
            </p>
          )}

          {!isLoadingStops &&
            !stopsError &&
            stops.map((stop, index) => (
              <div key={stop.stop_id} className="flex gap-2.5">
                <div className="flex flex-col items-center">
                  <span className="grid size-5 place-items-center rounded-full bg-blue-100 text-[10px] font-bold text-blue-700">
                    {index + 1}
                  </span>

                  {index !== stops.length - 1 && (
                    <div className="h-4 w-px bg-blue-200" />
                  )}
                </div>

                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-semibold text-slate-700">
                    {stop.stop_name}
                  </p>

                  <p className="truncate text-[10px] text-slate-400">
                    {stop.address}
                  </p>
                </div>

                {stop.estimated_time && (
                  <span className="text-[10px] text-slate-500">
                    {stop.estimated_time.slice(0, 5)}
                  </span>
                )}
              </div>
            ))}

          {!isLoadingStops &&
            !stopsError &&
            stops.length === 0 && (
              <p className="text-xs text-slate-400">
                Chưa có điểm dừng cho tuyến này.
              </p>
            )}
        </div>
      </div>
    </div>
  )
}
