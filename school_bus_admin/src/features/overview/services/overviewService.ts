import { supabase } from '@/lib/supabase'
import type {
  AbsenceItem,
  AlertItem,
  AttendanceDay,
  BusLocation,
  OverviewData,
  OverviewStats,
} from '../types/types'

const emptyStats: OverviewStats = {
  buses: 0,
  students: 0,
  staff: 0,
  alerts: 0,
  onboard: 0,
}

function localDate(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function getDateRange() {
  const now = new Date()
  const todayStart = new Date(now)
  todayStart.setHours(0, 0, 0, 0)

  const start = new Date(todayStart)
  start.setDate(start.getDate() - 5)

  const tomorrow = new Date(todayStart)
  tomorrow.setDate(tomorrow.getDate() + 1)

  return {
    today: localDate(now),
    startDate: localDate(start),
    startISO: start.toISOString(),
    todayISO: todayStart.toISOString(),
    tomorrowISO: tomorrow.toISOString(),
  }
}

function ensureNoError(error: { message: string } | null) {
  if (error) throw new Error(error.message)
}

export async function getOverviewData(): Promise<OverviewData> {
  const dates = getDateRange()

  // Các truy vấn độc lập. Tên bảng/cột đều theo file SQL của dự án.
  const [
    activeTripsResult,
    studentCountResult,
    staffCountResult,
    alertCountResult,
    alertsResult,
    absencesResult,
    attendanceResult,
  ] = await Promise.all([
    supabase
      .from('trips')
      .select('trip_id, bus_id, route_id')
      .eq('trip_date', dates.today)
      .eq('status', 'IN_PROGRESS'),

    supabase
      .from('students')
      .select('student_id', { count: 'exact', head: true })
      .eq('status', 'ACTIVE'),

    supabase
      .from('users')
      .select('user_id', { count: 'exact', head: true })
      .in('role', ['DRIVER', 'TEACHER'])
      .eq('is_active', true),

    supabase
      .from('alerts')
      .select('alert_id', { count: 'exact', head: true })
      .in('status', ['OPEN', 'PROCESSING']),

    supabase
      .from('alerts')
      .select('alert_id, title, message, severity, status, created_at')
      .in('status', ['OPEN', 'PROCESSING'])
      .order('created_at', { ascending: false })
      .limit(4),

    supabase
      .from('absences')
      .select('absence_id, student_id, absence_date, session, reason, status')
      .eq('status', 'PENDING')
      .order('absence_date', { ascending: true })
      .limit(5),

    supabase
      .from('attendance')
      .select('attendance_id, check_in_time, detection_method')
      .gte('check_in_time', dates.startISO)
      .lt('check_in_time', dates.tomorrowISO)
      .order('check_in_time', { ascending: true }),
  ])

  ensureNoError(activeTripsResult.error)
  ensureNoError(studentCountResult.error)
  ensureNoError(staffCountResult.error)
  ensureNoError(alertCountResult.error)
  ensureNoError(alertsResult.error)
  ensureNoError(absencesResult.error)
  ensureNoError(attendanceResult.error)

  const activeTrips = activeTripsResult.data ?? []
  const tripIds = activeTrips.map((trip) => trip.trip_id)
  const busIds = [...new Set(activeTrips.map((trip) => trip.bus_id))]

  // Đếm học sinh đã lên xe trong các chuyến đang chạy.
  let onboard = 0
  if (tripIds.length > 0) {
    const { count, error } = await supabase
      .from('attendance')
      .select('attendance_id', { count: 'exact', head: true })
      .in('trip_id', tripIds)
      .eq('status', 'BOARDED')

    ensureNoError(error)
    onboard = count ?? 0
  }

  // Ghép đơn xin nghỉ với học sinh bằng student_id.
  // SQL không khai báo FK trực tiếp absences -> students.
  const absenceRows = absencesResult.data ?? []
  const absenceStudentIds = [...new Set(absenceRows.map((item) => item.student_id))]
  let studentMap = new Map<string, { full_name: string; class_name: string | null }>()

  if (absenceStudentIds.length > 0) {
    const { data, error } = await supabase
      .from('students')
      .select('student_id, full_name, class_name')
      .in('student_id', absenceStudentIds)

    ensureNoError(error)
    studentMap = new Map(
      (data ?? []).map((student) => [
        student.student_id,
        { full_name: student.full_name, class_name: student.class_name },
      ]),
    )
  }

  const absences: AbsenceItem[] = absenceRows.map((item) => {
    const student = studentMap.get(item.student_id)
    return {
      absence_id: item.absence_id,
      student_id: item.student_id,
      absence_date: item.absence_date,
      session: item.session,
      reason: item.reason,
      status: item.status,
      student_name: student?.full_name ?? 'Không tìm thấy học sinh',
      class_name: student?.class_name ?? null,
    }
  })

  // Tạo biểu đồ 6 ngày gần nhất, kể cả ngày không có lượt điểm danh.
  const attendanceRows = attendanceResult.data ?? []
  const attendanceChart: AttendanceDay[] = []
  for (let i = 5; i >= 0; i -= 1) {
    const date = new Date()
    date.setHours(0, 0, 0, 0)
    date.setDate(date.getDate() - i)
    const key = localDate(date)
    const value = attendanceRows.filter(
      (row) => row.check_in_time?.slice(0, 10) === key,
    ).length

    attendanceChart.push({
      day:
        i === 0
          ? 'Hôm nay'
          : date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
      value,
    })
  }

  const todayAttendance = attendanceRows.filter((row) => {
    if (!row.check_in_time) return false
    const datePart = row.check_in_time.slice(0, 10)
    return datePart === dates.today
  })
  const aiCount = todayAttendance.filter(
    (row) => row.detection_method === 'AI',
  ).length
  const aiPercent =
    todayAttendance.length > 0
      ? Math.round((aiCount / todayAttendance.length) * 100)
      : 0

  // GPS mới nhất của từng chuyến đang chạy.
  let locations: BusLocation[] = []
  if (tripIds.length > 0) {
    const [{ data: gpsRows, error: gpsError }, { data: buses, error: busError }] =
      await Promise.all([
        supabase
          .from('gps_locations')
          .select('gps_id, trip_id, latitude, longitude, speed, recorded_at')
          .in('trip_id', tripIds)
          .order('recorded_at', { ascending: false }),
        busIds.length > 0
          ? supabase.from('buses').select('bus_id, license_plate').in('bus_id', busIds)
          : Promise.resolve({ data: [], error: null }),
      ])

    ensureNoError(gpsError)
    ensureNoError(busError)

    const latestGps = new Map<string, NonNullable<typeof gpsRows>[number]>()
    for (const gps of gpsRows ?? []) {
      if (!latestGps.has(gps.trip_id)) latestGps.set(gps.trip_id, gps)
    }

    const plateMap = new Map(
      (buses ?? []).map((bus) => [bus.bus_id, bus.license_plate]),
    )

    locations = activeTrips.flatMap((trip) => {
      const gps = latestGps.get(trip.trip_id)
      if (!gps) return []
      return [{
        trip_id: trip.trip_id,
        bus_id: trip.bus_id,
        route_id: trip.route_id,
        license_plate: plateMap.get(trip.bus_id) ?? 'Chưa rõ biển số',
        latitude: Number(gps.latitude),
        longitude: Number(gps.longitude),
        speed: gps.speed === null ? null : Number(gps.speed),
      }]
    })
  }

  return {
    stats: {
      ...emptyStats,
      buses: new Set(activeTrips.map((trip) => trip.bus_id)).size,
      students: studentCountResult.count ?? 0,
      staff: staffCountResult.count ?? 0,
      alerts: alertCountResult.count ?? 0,
      onboard,
    },
    alerts: (alertsResult.data ?? []) as AlertItem[],
    absences,
    attendanceChart,
    aiPercent,
    locations,
  }
}

export async function updateAbsenceStatus(
  absenceId: string,
  status: 'APPROVED' | 'REJECTED',
) {
  const { data: authData, error: authError } = await supabase.auth.getUser()
  ensureNoError(authError)
  const userId = authData.user?.id
  if (!userId) throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.')

  const { data, error } = await supabase
    .from('absences')
    .update({
      status,
      reviewed_by: userId,
      reviewed_at: new Date().toISOString(),
    })
    .eq('absence_id', absenceId)
    .eq('status', 'PENDING')
    .select('absence_id')
    .maybeSingle()

  ensureNoError(error)
  if (!data) {
    throw new Error('Đơn đã được xử lý hoặc bạn không có quyền cập nhật đơn này.')
  }
}
