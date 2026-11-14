export interface FleetLiveItem {
  trip_id: string
  trip_date: string
  trip_type: 'MORNING' | 'AFTERNOON'
  start_at: string
  end_at: string
  trip_status: string

  bus_id: string
  bus_code: string
  license_plate: string
  capacity: number
  vehicle_model: string | null
  bus_status: string

  route_id: string
  route_code: string
  route_name: string
  start_location: string | null
  end_location: string | null

  latitude: number | null
  longitude: number | null
  speed: number | null
  heading: number | null
  accuracy: number | null
  gps_recorded_at: string | null

  boarded_count: number
  total_students: number
}