
import { Clock, CircleCheck } from 'lucide-react'

import { FleetHeader } from './components/FleetHeader'
import { VehicleList } from './components/VehicleList'
import { FleetMap } from './components/FleetMap'
import { VehicleDetail } from './components/VehicleDetail'
import { useFleet } from './hooks/useFleet'

export function FleetPage() {
  const {
    buses,
    routes,
    stops,
    fleetLive,

    filteredBuses,
    selectedBus,
    selectedRoute,

    selectedBusId,
    selectedRouteId,

    filter,
    setFilter,
    setSelectedBusId,
    setSelectedRouteId,

    counts,
    refresh,
  } = useFleet()

  const isRefreshing =
    buses.isFetching ||
    routes.isFetching ||
    fleetLive.isFetching

  return (
    <div className="flex min-h-[calc(100vh-80px)] flex-col gap-4">

      {/* HEADER */}
      <FleetHeader
        total={counts.all}
        onRefresh={refresh}
        isRefreshing={isRefreshing}
      />

      {/* MAIN CONTENT */}
      <div className="grid min-h-[680px] flex-1 grid-cols-1 gap-4 xl:grid-cols-[340px_minmax(0,1fr)]">

        {/* LEFT: VEHICLE LIST */}
        <VehicleList
          buses={filteredBuses}
          selectedBusId={selectedBusId}
          filter={filter}
          counts={counts}
          isLoading={buses.isLoading}
          error={buses.error as Error | null}
          onFilterChange={setFilter}
          onSelectBus={setSelectedBusId}
        />

        {/* RIGHT: MAP AND DETAILS */}
        <section className="flex min-h-[600px] flex-col gap-3">

          {/* MAP */}
          <FleetMap
            selectedBus={selectedBus}
            routes={routes.data ?? []}
            selectedRouteId={selectedRouteId}
            onSelectRoute={setSelectedRouteId}
            onRefresh={refresh}

            // GPS từ gps_locations
            locations={fleetLive.data ?? []}

            // Điểm dừng từ route_stops
            stops={stops.data ?? []}

            // Chọn xe khi click marker trên bản đồ
            onSelectBus={setSelectedBusId}
          />

          {/* VEHICLE DETAIL */}
          <VehicleDetail
            bus={selectedBus}
            route={selectedRoute}
            stops={stops.data ?? []}
            isLoadingStops={stops.isLoading}
            stopsError={stops.error as Error | null}
          />

        </section>
      </div>

      {/* FOOTER STATUS */}
      <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-slate-400">

        <div className="flex items-center gap-2">
          <CircleCheck className="size-3.5 text-green-500" />
          Hệ thống quản lý đội xe
        </div>

        <div className="flex items-center gap-2">
          <Clock className="size-3.5" />

          {fleetLive.isError
            ? 'Không thể cập nhật dữ liệu GPS'
            : 'GPS tự động cập nhật mỗi 15 giây'}
        </div>

      </div>
    </div>
  )
}

export default FleetPage
