
import { useEffect, useMemo } from 'react'
import { LocateFixed } from 'lucide-react'

import {
  MapContainer,
  Marker,
  Popup,
  TileLayer,
  Polyline,
  useMap,
} from 'react-leaflet'

import L from 'leaflet'

import type {
  BusItem,
  BusLocation,
  RouteItem,
  RouteStop,
} from '../types/fleet.types'

interface FleetMapProps {
  selectedBus: BusItem | null
  routes: RouteItem[]
  selectedRouteId: string | null
  onSelectRoute: (routeId: string) => void
  onRefresh: () => void

  // Dữ liệu GPS của các xe đang chạy
  locations: BusLocation[]

  // Điểm dừng của tuyến đang chọn
  stops: RouteStop[]

  // Chọn xe khi nhấn marker
  onSelectBus: (busId: string) => void
}

// =====================================================
// ICON XE
// =====================================================

const createBusIcon = (selected = false) =>
  L.divIcon({
    className: '',
    html: `
      <div style="
        width: ${selected ? 46 : 40}px;
        height: ${selected ? 46 : 40}px;
        border-radius: 50%;
        background: ${selected ? '#ea580c' : '#2563eb'};
        border: 3px solid white;
        box-shadow: 0 2px 8px rgba(0,0,0,0.25);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: ${selected ? 22 : 19}px;
      ">
        🚌
      </div>
    `,
    iconSize: selected ? [46, 46] : [40, 40],
    iconAnchor: selected ? [23, 23] : [20, 20],
    popupAnchor: [0, -20],
  })

const busIcon = createBusIcon(false)
const selectedBusIcon = createBusIcon(true)

// =====================================================
// ICON ĐIỂM DỪNG
// =====================================================

const stopIcon = L.divIcon({
  className: '',
  html: `
    <div style="
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: #16a34a;
      border: 3px solid white;
      box-shadow: 0 1px 5px rgba(0,0,0,0.3);
    "></div>
  `,
  iconSize: [20, 20],
  iconAnchor: [10, 10],
})

// =====================================================
// TỰ ĐỘNG ĐƯA BẢN ĐỒ TỚI XE ĐANG CHỌN
// =====================================================

interface MapFocusProps {
  position: [number, number] | null
}

function MapFocus({ position }: MapFocusProps) {
  const map = useMap()

  useEffect(() => {
    if (position) {
      map.flyTo(position, 15, {
        duration: 1,
      })
    }
  }, [map, position])

  return null
}

// =====================================================
// FORMAT THỜI GIAN
// =====================================================

function formatTime(value: string) {
  return new Date(value).toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
}

// =====================================================
// COMPONENT CHÍNH
// =====================================================

export function FleetMap({
  selectedBus,
  routes,
  selectedRouteId,
  onSelectRoute,
  onRefresh,
  locations,
  stops,
  onSelectBus,
}: FleetMapProps) {
  // Vị trí GPS của xe đang chọn
  const selectedLocation = locations.find(
    (location) => location.bus_id === selectedBus?.bus_id
  )

  const selectedPosition: [number, number] | null =
    selectedLocation
      ? [
          selectedLocation.latitude,
          selectedLocation.longitude,
        ]
      : null

  // Các điểm dừng có tọa độ hợp lệ
  const validStops = useMemo(() => {
    return stops
      .filter(
        (stop) =>
          stop.latitude != null &&
          stop.longitude != null &&
          Number.isFinite(Number(stop.latitude)) &&
          Number.isFinite(Number(stop.longitude))
      )
      .sort((a, b) => a.stop_order - b.stop_order)
  }, [stops])

  // Đường nối các điểm dừng
  const routePositions = useMemo(() => {
    return validStops.map(
      (stop): [number, number] => [
        Number(stop.latitude),
        Number(stop.longitude),
      ]
    )
  }, [validStops])

  // Tâm bản đồ
  const center: [number, number] =
    selectedPosition ??
    routePositions[0] ??
    (locations.length > 0
      ? [locations[0].latitude, locations[0].longitude]
      : [16.0471, 108.2068])

  // =====================================================
  // RENDER
  // =====================================================

  return (
    <div className="relative min-h-[460px] flex-1 overflow-hidden rounded-2xl border border-slate-200 bg-[#f5f1e2] shadow-sm">

      {/* BẢN ĐỒ THẬT */}
      <MapContainer
        center={center}
        zoom={13}
        scrollWheelZoom
        className="absolute inset-0 z-0 h-full w-full"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Tự động focus xe đang chọn */}
        <MapFocus position={selectedPosition} />

        {/* Tuyến đường qua các điểm dừng */}
        {routePositions.length >= 2 && (
          <Polyline
            positions={routePositions}
            pathOptions={{
              color: '#2563eb',
              weight: 5,
              opacity: 0.85,
              lineCap: 'round',
              lineJoin: 'round',
            }}
          />
        )}

        {/* Các điểm dừng */}
        {validStops.map((stop) => (
          <Marker
            key={stop.stop_id}
            position={[
              Number(stop.latitude),
              Number(stop.longitude),
            ]}
            icon={stopIcon}
          >
            <Popup>
              <div className="min-w-[160px]">
                <p className="font-semibold text-slate-800">
                  {stop.stop_name}
                </p>

                <p className="mt-1 text-sm text-slate-600">
                  {stop.address}
                </p>

                <p className="mt-1 text-xs text-slate-500">
                  Điểm dừng thứ {stop.stop_order}
                </p>

                {stop.estimated_time && (
                  <p className="mt-1 text-xs text-slate-500">
                    Giờ dự kiến: {stop.estimated_time}
                  </p>
                )}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Các xe có dữ liệu GPS */}
        {locations.map((location) => {
          const isSelected =
            location.bus_id === selectedBus?.bus_id

          return (
            <Marker
              key={location.gps_id}
              position={[
                location.latitude,
                location.longitude,
              ]}
              icon={
                isSelected
                  ? selectedBusIcon
                  : busIcon
              }
              eventHandlers={{
                click: () => onSelectBus(location.bus_id),
              }}
            >
              <Popup>
                <div className="min-w-[180px] space-y-1">
                  <p className="font-semibold text-slate-800">
                    {location.bus_code}
                  </p>

                  <p className="text-sm text-slate-600">
                    Biển số: {location.license_plate}
                  </p>

                  <p className="text-sm text-slate-600">
                    Tốc độ: {location.speed ?? 0} km/h
                  </p>

                  <p className="text-xs text-slate-500">
                    GPS: {location.latitude.toFixed(6)},
                    {' '}
                    {location.longitude.toFixed(6)}
                  </p>

                  <p className="text-xs text-slate-500">
                    Cập nhật: {formatTime(location.recorded_at)}
                  </p>
                </div>
              </Popup>
            </Marker>
          )
        })}
      </MapContainer>

      {/* MAP STATUS */}
      <div className="absolute left-4 top-4 z-[1000] flex items-center gap-2 rounded-full border border-slate-100 bg-white/95 px-3 py-2 shadow-sm">
        <span className="relative flex size-2">
          <span className="absolute inline-flex size-full animate-ping rounded-full bg-green-400 opacity-75" />
          <span className="relative inline-flex size-2 rounded-full bg-green-500" />
        </span>

        <span className="text-xs font-semibold text-slate-700">
          Theo dõi dữ liệu xe
        </span>
      </div>

      {/* SELECTED BUS */}
      <div className="absolute left-4 top-16 z-[1000] rounded-xl border border-slate-100 bg-white/95 px-4 py-3 shadow-sm">
        {selectedBus ? (
          <>
            <p className="text-sm font-bold text-slate-800">
              {selectedBus.license_plate}
            </p>

            <p className="text-[10px] text-slate-400">
              {selectedBus.bus_code}
            </p>

            <p className="mt-1 text-xs">
              {selectedLocation
                ? 'Đã có vị trí GPS'
                : 'Chưa có vị trí GPS'}
            </p>
          </>
        ) : (
          <p className="text-xs text-slate-500">
            Chưa chọn xe
          </p>
        )}
      </div>

      {/* ROUTE SELECTOR */}
      <div className="absolute right-4 top-4 z-[1000]">
        <select
          value={selectedRouteId ?? ''}
          onChange={(event) => onSelectRoute(event.target.value)}
          className="max-w-48 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 shadow-sm outline-none"
        >
          <option value="" disabled>
            Chọn tuyến xe
          </option>

          {routes.map((route) => (
            <option
              key={route.route_id}
              value={route.route_id}
            >
              {route.route_name}
            </option>
          ))}
        </select>
      </div>

      {/* MAP INFORMATION */}
      <div className="absolute bottom-4 left-4 z-[1000] rounded-xl border border-slate-100 bg-white/95 px-3 py-2 shadow-sm">
        <p className="text-xs text-slate-600">
          Xe có GPS: <strong>{locations.length}</strong>
        </p>

        <p className="text-xs text-slate-600">
          Điểm dừng: <strong>{validStops.length}</strong>
        </p>
      </div>

      {/* MAP CONTROL */}
      <button
        type="button"
        title="Làm mới dữ liệu"
        onClick={onRefresh}
        className="absolute bottom-4 right-4 z-[1000] grid size-10 place-items-center rounded-xl bg-white text-slate-600 shadow-md hover:bg-slate-50"
      >
        <LocateFixed className="size-5" />
      </button>
    </div>
  )
}

export default FleetMap
