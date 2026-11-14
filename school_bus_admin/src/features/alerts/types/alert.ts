
export type AlertStatus =
  | 'OPEN'
  | 'PROCESSING'
  | 'RESOLVED'
  | 'CLOSED'

export type AlertSeverity =
  | 'LOW'
  | 'MEDIUM'
  | 'HIGH'
  | 'CRITICAL'

export type AlertType =
  | 'STUDENT_NOT_BOARDED'
  | 'STUDENT_NOT_ALIGHTED'
  | 'UNEXPECTED_STOP'
  | 'GPS_LOST'
  | 'TRIP_DELAY'
  | 'MANUAL_ALERT'
  | 'INCIDENT'
  | 'OTHER'

export type AlertLevel = 'WARNING' | 'DANGER' | 'INFO'

export type AlertTab = 'ALL' | 'PENDING' | 'RESOLVED'

export interface AlertItem {
  id: string
  tripId: string | null
  studentId: string | null

  title: string
  type: AlertLevel
  severity: AlertSeverity
  alertType: AlertType
  category: string

  busPlate: string
  routeName: string

  time: string
  createdAt: string

  status: AlertStatus
  description: string

  incidentLocation: string | null
  resolutionNote: string | null
  reportedBy: string | null
}

export interface AlertStats {
  danger: number
  warning: number
  pending: number
  total: number
}
