
export type BusStatus = 'ACTIVE' | 'MAINTENANCE' | 'INACTIVE'

export type FilterType = 'ALL' | BusStatus

export interface BusItem {
  bus_id: string
  bus_code: string
  license_plate: string
  capacity: number
  vehicle_model: string | null
  status: BusStatus
}

export interface RouteItem {
  route_id: string
  route_code: string
  route_name: string
  start_location: string | null
  end_location: string | null
  status: 'ACTIVE' | 'INACTIVE'
}

export interface RouteStop {
  stop_id: string
  stop_name: string
  address: string
  stop_order: number
  estimated_time: string | null
}

export interface FleetCounts {
  all: number
  active: number
  warning: number
  inactive: number
}

export const statusConfig: Record<
  BusStatus,
  {
    label: string
    className: string
    dot: string
  }
> = {
  ACTIVE: {
    label: 'Đang hoạt động',
    className: 'bg-blue-100 text-blue-700',
    dot: 'bg-blue-500',
  },
  MAINTENANCE: {
    label: 'Cảnh báo',
    className: 'bg-red-100 text-red-600',
    dot: 'bg-red-500',
  },
  INACTIVE: {
    label: 'Ngừng hoạt động',
    className: 'bg-slate-100 text-slate-500',
    dot: 'bg-slate-400',
  },
}

export const filters: {
  label: string
  value: FilterType
}[] = [
  { label: 'Tất cả', value: 'ALL' },
  { label: 'Hoạt động', value: 'ACTIVE' },
  { label: 'Cảnh báo', value: 'MAINTENANCE' },
  { label: 'Ngừng', value: 'INACTIVE' },
]

export function normalizeBusStatus(status: unknown): BusStatus {
  const value = String(status ?? '').trim().toUpperCase()

  if (value === 'ACTIVE') return 'ACTIVE'
  if (value === 'MAINTENANCE') return 'MAINTENANCE'
  if (value === 'INACTIVE') return 'INACTIVE'

  return 'INACTIVE'
}

export interface BusLocation {
  gps_id: string
  trip_id: string
  bus_id: string
  bus_code: string
  license_plate: string
  route_id: string
  trip_status: 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  latitude: number
  longitude: number
  speed: number | null
  heading: number | null
  accuracy: number | null
  recorded_at: string
}
