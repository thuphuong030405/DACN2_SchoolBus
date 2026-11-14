export type OverviewStats = {
  buses: number
  students: number
  staff: number
  alerts: number
  onboard: number
}

export type AlertItem = {
  alert_id: string
  title: string
  message: string
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' | string
  status: 'OPEN' | 'PROCESSING' | 'RESOLVED' | 'CLOSED' | string
  created_at: string
}

export type AbsenceItem = {
  absence_id: string
  student_id: string
  absence_date: string
  session: 'MORNING' | 'AFTERNOON' | string
  reason: string
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | string
  student_name: string
  class_name: string | null
}

export type AttendanceDay = {
  day: string
  value: number
}

export type BusLocation = {
  trip_id: string
  bus_id: string
  license_plate: string
  route_id: string
  latitude: number
  longitude: number
  speed: number | null
}

export type OverviewData = {
  stats: OverviewStats
  alerts: AlertItem[]
  absences: AbsenceItem[]
  attendanceChart: AttendanceDay[]
  aiPercent: number
  locations: BusLocation[]
}
