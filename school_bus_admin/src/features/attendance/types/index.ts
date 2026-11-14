export type AttendanceStatus = 'PENDING' | 'BOARDED' | 'ALIGHTED' | 'ABSENT'
export type DetectionMethod = 'AI' | 'MANUAL'

export interface TripOption {
  trip_id: string
  trip_date: string
  trip_type: 'MORNING' | 'AFTERNOON'
  status: 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  route_id: string
  route_code: string
  route_name: string
  bus_plate: string
}

export interface StudentAttendanceRow {
  attendance_id?: string
  student_id: string
  student_code: string
  full_name: string
  pickup_stop_id: string | null
  pickup_stop_name: string
  check_in_time: string | null
  check_out_time: string | null
  detection_method: DetectionMethod | null
  ai_confidence: number | null
  status: AttendanceStatus
}

export interface RouteProgressItem {
  route_id: string
  route_name: string
  boarded_count: number
  total_count: number
}

export interface AttendanceSummary {
  expected_today: number
  boarded_today: number
  ai_rate: number
  pending_today: number
  absent_today: number
}