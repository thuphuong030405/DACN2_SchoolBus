
import { supabase } from '@/lib/supabase'

import type {
  AlertItem,
  AlertLevel,
  AlertSeverity,
  AlertStatus,
  AlertType,
} from '../types'

// ========================================
// DATABASE TYPES
// ========================================

interface AlertRow {
  alert_id: string
  trip_id: string | null
  student_id: string | null
  alert_type: AlertType
  severity: AlertSeverity
  title: string
  message: string | null
  reported_by: string | null
  incident_location: string | null
  resolution_note: string | null
  status: AlertStatus
  created_at: string
  updated_at: string
}

interface TripRow {
  trip_id: string
  bus_id: string | null
  route_id: string | null
}

interface BusRow {
  bus_id: string
  bus_code: string
  license_plate: string
}

interface RouteRow {
  route_id: string
  route_code: string
  route_name: string
}

// ========================================
// FORMAT HELPERS
// ========================================

function getAlertLevel(severity: AlertSeverity): AlertLevel {
  switch (severity) {
    case 'CRITICAL':
    case 'HIGH':
      return 'DANGER'

    case 'MEDIUM':
      return 'WARNING'

    case 'LOW':
    default:
      return 'INFO'
  }
}

function getAlertCategory(alertType: AlertType): string {
  const categories: Record<AlertType, string> = {
    STUDENT_NOT_BOARDED: 'Học sinh',
    STUDENT_NOT_ALIGHTED: 'Học sinh',
    UNEXPECTED_STOP: 'Lộ trình',
    GPS_LOST: 'Thiết bị',
    TRIP_DELAY: 'Lịch trình',
    MANUAL_ALERT: 'Thủ công',
    INCIDENT: 'Sự cố',
    OTHER: 'Khác',
  }

  return categories[alertType] ?? 'Khác'
}

function formatAlertTime(dateString: string): string {
  const date = new Date(dateString)

  if (Number.isNaN(date.getTime())) {
    return dateString
  }

  return new Intl.DateTimeFormat('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(date)
}

// ========================================
// GET ALERTS
// ========================================

export async function getAlerts(): Promise<AlertItem[]> {
  // 1. Lấy cảnh báo
  const { data: alertData, error: alertError } = await supabase
    .from('alerts')
    .select(`
      alert_id,
      trip_id,
      student_id,
      alert_type,
      severity,
      title,
      message,
      reported_by,
      incident_location,
      resolution_note,
      status,
      created_at,
      updated_at
    `)
    .order('created_at', { ascending: false })

  if (alertError) {
    console.error('getAlerts - alerts:', alertError)
    throw new Error(alertError.message)
  }

  const alerts = (alertData ?? []) as AlertRow[]

  if (alerts.length === 0) {
    return []
  }

  // 2. Lấy danh sách chuyến xe
  const tripIds = [
    ...new Set(
      alerts
        .map((item) => item.trip_id)
        .filter((id): id is string => Boolean(id)),
    ),
  ]

  let trips: TripRow[] = []

  if (tripIds.length > 0) {
    const { data, error } = await supabase
      .from('trips')
      .select(`
        trip_id,
        bus_id,
        route_id
      `)
      .in('trip_id', tripIds)

    if (error) {
      console.error('getAlerts - trips:', error)
      throw new Error(error.message)
    }

    trips = (data ?? []) as TripRow[]
  }

  const tripMap = new Map(
    trips.map((item) => [item.trip_id, item]),
  )

  // 3. Lấy thông tin xe
  const busIds = [
    ...new Set(
      trips
        .map((item) => item.bus_id)
        .filter((id): id is string => Boolean(id)),
    ),
  ]

  let buses: BusRow[] = []

  if (busIds.length > 0) {
    const { data, error } = await supabase
      .from('buses')
      .select(`
        bus_id,
        bus_code,
        license_plate
      `)
      .in('bus_id', busIds)

    if (error) {
      console.error('getAlerts - buses:', error)
      throw new Error(error.message)
    }

    buses = (data ?? []) as BusRow[]
  }

  const busMap = new Map(
    buses.map((item) => [item.bus_id, item]),
  )

  // 4. Lấy thông tin tuyến đường
  const routeIds = [
    ...new Set(
      trips
        .map((item) => item.route_id)
        .filter((id): id is string => Boolean(id)),
    ),
  ]

  let routes: RouteRow[] = []

  if (routeIds.length > 0) {
    const { data, error } = await supabase
      .from('routes')
      .select(`
        route_id,
        route_code,
        route_name
      `)
      .in('route_id', routeIds)

    if (error) {
      console.error('getAlerts - routes:', error)
      throw new Error(error.message)
    }

    routes = (data ?? []) as RouteRow[]
  }

  const routeMap = new Map(
    routes.map((item) => [item.route_id, item]),
  )

  // 5. Ghép dữ liệu
  return alerts.map((alert) => {
    const trip = alert.trip_id
      ? tripMap.get(alert.trip_id)
      : undefined

    const bus = trip?.bus_id
      ? busMap.get(trip.bus_id)
      : undefined

    const route = trip?.route_id
      ? routeMap.get(trip.route_id)
      : undefined

    return {
      id: alert.alert_id,
      tripId: alert.trip_id,
      studentId: alert.student_id,

      title: alert.title,
      type: getAlertLevel(alert.severity),
      severity: alert.severity,
      alertType: alert.alert_type,
      category: getAlertCategory(alert.alert_type),

      busPlate:
        bus?.license_plate ||
        bus?.bus_code ||
        'Chưa xác định',

      routeName: route
        ? `${route.route_code} - ${route.route_name}`
        : 'Chưa xác định',

      time: formatAlertTime(alert.created_at),
      createdAt: alert.created_at,

      status: alert.status,
      description:
        alert.message || 'Không có mô tả chi tiết.',

      incidentLocation: alert.incident_location,
      resolutionNote: alert.resolution_note,
      reportedBy: alert.reported_by,
    }
  })
}

// ========================================
// UPDATE ALERT STATUS
// ========================================

export async function updateAlertStatus(
  alertId: string,
  resolutionNote?: string,
): Promise<void> {
  // Kiểm tra tài khoản đăng nhập
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser()

  if (authError) {
    throw new Error(authError.message)
  }

  if (!user) {
    throw new Error('Bạn cần đăng nhập để xử lý cảnh báo.')
  }

  // Cập nhật trạng thái cảnh báo
  const { data, error } = await supabase
    .from('alerts')
    .update({
      status: 'RESOLVED',
      resolution_note: resolutionNote?.trim() || null,
      updated_at: new Date().toISOString(),
    })
    .eq('alert_id', alertId)
    .in('status', ['OPEN', 'PROCESSING'])
    .select('alert_id')
    .maybeSingle()

  if (error) {
    console.error('updateAlertStatus:', error)
    throw new Error(error.message)
  }

  if (!data) {
    throw new Error(
      'Cảnh báo không tồn tại hoặc đã được xử lý trước đó.',
    )
  }
}

// ========================================
// CALCULATE STATISTICS
// ========================================

export function calculateAlertStats(
  alerts: AlertItem[],
) {
  const pendingAlerts = alerts.filter(
    (item) =>
      item.status === 'OPEN' ||
      item.status === 'PROCESSING',
  )

  return {
    danger: pendingAlerts.filter(
      (item) => item.type === 'DANGER',
    ).length,

    warning: pendingAlerts.filter(
      (item) => item.type === 'WARNING',
    ).length,

    pending: pendingAlerts.length,

    total: alerts.length,
  }
}
