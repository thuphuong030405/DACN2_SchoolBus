
export type UUID = string

export type BusStatus =
  | 'ACTIVE'
  | 'MAINTENANCE'
  | 'INACTIVE'

export type TripStatus =
  | 'SCHEDULED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED'

export type TripType = 'MORNING' | 'AFTERNOON'

export interface Bus {
  bus_id: UUID
  bus_code: string
  license_plate: string
  capacity: number
  vehicle_model: string | null
  status: BusStatus
  created_at: string
  updated_at: string
}

export interface RouteStop {
  stop_id: UUID
  route_id: UUID
  stop_name: string
  address: string
  latitude: number | null
  longitude: number | null
  stop_order: number
  estimated_time: string | null
  is_active: boolean
}

export interface BusRoute {
  route_id: UUID
  route_code: string
  route_name: string
  description: string | null
  start_location: string | null
  end_location: string | null
  estimated_duration: number | null
  status: 'ACTIVE' | 'INACTIVE'
  route_stops: RouteStop[]
}

export interface UserProfile {
  user_id: UUID
  full_name: string
  email: string
  phone: string | null
  avatar_url: string | null
}

export interface Driver {
  driver_id: UUID
  user_id: UUID
  driver_code: string
  license_number: string
  license_expiry: string | null
  users: UserProfile | null
}

export interface Teacher {
  teacher_id: UUID
  user_id: UUID
  teacher_code: string
  department: string | null
  users: UserProfile | null
}

export interface GpsLocation {
  gps_id: UUID
  trip_id: UUID
  latitude: number
  longitude: number
  speed: number | null
  heading: number | null
  accuracy: number | null
  recorded_at: string
}

export interface Trip {
  trip_id: UUID
  bus_id: UUID
  route_id: UUID
  teacher_id: UUID
  driver_id: UUID
  trip_date: string
  trip_type: TripType
  start_at: string
  end_at: string
  status: TripStatus

  buses: Bus | null
  routes: BusRoute | null
  drivers: Driver | null
  teachers: Teacher | null
  gps_locations: GpsLocation[]
}

export interface BusWithTrip extends Bus {
  currentTrip: Trip | null
  driverName: string
  teacherName: string
  routeName: string
  latestGps: GpsLocation | null
}

export interface RouteSummary extends BusRoute {
  busCount: number
  activeBusCount: number
  stops: RouteStop[]
}

export interface RoutesData {
  buses: BusWithTrip[]
  routes: RouteSummary[]
  trips: Trip[]
  gpsLocations: GpsLocation[]
}
