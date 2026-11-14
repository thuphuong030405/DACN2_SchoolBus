import { supabase } from '@/lib/supabase'
import type {
  AttendanceSummary,
  RouteProgressItem,
  StudentAttendanceRow,
  TripOption,
} from '../types'

function getTodayVN(): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh',
  }).format(new Date())
}

export const attendanceService = {
 // 1. Lấy danh sách các chuyến xe của ĐÚNG 1 NGÀY (hôm nay hoặc ngày gần nhất có dữ liệu)
  async getTrips(): Promise<TripOption[]> {
    const today = getTodayVN()

    // Kiểm tra hôm nay có chuyến không
    let { data, error } = await supabase
      .from('trips')
      .select(`
        trip_id,
        trip_date,
        trip_type,
        status,
        route_id,
        routes ( route_code, route_name ),
        buses ( license_plate )
      `)
      .eq('trip_date', today)
      .order('start_at', { ascending: true })

    if (error) throw error

    // Nếu hôm nay chưa có chuyến -> tìm ngày gần nhất có chuyến và lấy TẤT CẢ chuyến của đúng ngày đó
    if (!data || data.length === 0) {
      const { data: latestRow, error: latestErr } = await supabase
        .from('trips')
        .select('trip_date')
        .order('trip_date', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (latestErr) throw latestErr

      if (latestRow?.trip_date) {
        const res = await supabase
          .from('trips')
          .select(`
            trip_id,
            trip_date,
            trip_type,
            status,
            route_id,
            routes ( route_code, route_name ),
            buses ( license_plate )
          `)
          .eq('trip_date', latestRow.trip_date)
          .order('start_at', { ascending: true })

        if (res.error) throw res.error
        data = res.data
      }
    }

    return (data ?? []).map((t: any) => ({
      trip_id: t.trip_id,
      trip_date: t.trip_date,
      trip_type: t.trip_type,
      status: t.status,
      route_id: t.route_id,
      route_code: t.routes?.route_code ?? '',
      route_name: t.routes?.route_name ?? 'Tuyến chưa đặt tên',
      bus_plate: t.buses?.license_plate ?? 'Chưa gán xe',
    }))
  },

  // 2. Lấy chi tiết danh sách học sinh & trạng thái điểm danh của 1 chuyến
  async getTripAttendance(trip: TripOption): Promise<StudentAttendanceRow[]> {
    const { data: studentRoutes, error: srErr } = await supabase
      .from('student_routes')
      .select(`
        student_id,
        pickup_stop_id,
        students!inner ( student_id, student_code, full_name, status ),
        pickup_stop:route_stops!student_routes_route_id_pickup_stop_id_fkey ( stop_name )
      `)
      .eq('route_id', trip.route_id)
      .eq('status', 'ACTIVE')

    if (srErr) throw srErr

    const { data: attRecords, error: attErr } = await supabase
      .from('attendance')
      .select('*')
      .eq('trip_id', trip.trip_id)

    if (attErr) throw attErr

    const attMap = new Map(
      (attRecords ?? []).map((rec: any) => [rec.student_id, rec])
    )

    // Dùng Map theo student_id để khử trùng lặp nếu học sinh có nhiều bản ghi phân tuyến
    const uniqueStudentsMap = new Map<string, StudentAttendanceRow>()

    for (const sr of studentRoutes ?? []) {
      if (uniqueStudentsMap.has(sr.student_id)) continue

      const st = Array.isArray(sr.students) ? sr.students[0] : sr.students
      const stop = Array.isArray(sr.pickup_stop) ? sr.pickup_stop[0] : sr.pickup_stop
      const att = attMap.get(sr.student_id)

      uniqueStudentsMap.set(sr.student_id, {
        attendance_id: att?.attendance_id,
        student_id: sr.student_id,
        student_code: st?.student_code ?? '',
        full_name: st?.full_name ?? 'Học sinh',
        pickup_stop_id: sr.pickup_stop_id ?? null,
        pickup_stop_name: stop?.stop_name ?? 'Chưa cập nhật điểm đón',
        check_in_time: att?.check_in_time ?? null,
        check_out_time: att?.check_out_time ?? null,
        detection_method: att?.detection_method ?? null,
        ai_confidence: att?.ai_confidence ? Number(att.ai_confidence) : null,
        status: att?.status ?? 'PENDING',
      })
    }

    // Bổ sung các học sinh đã có trong bảng attendance nhưng chưa có trong student_routes
    for (const att of attRecords ?? []) {
      if (!uniqueStudentsMap.has(att.student_id)) {
        const { data: st } = await supabase
          .from('students')
          .select('student_code, full_name')
          .eq('student_id', att.student_id)
          .single()

        uniqueStudentsMap.set(att.student_id, {
          attendance_id: att.attendance_id,
          student_id: att.student_id,
          student_code: st?.student_code ?? '',
          full_name: st?.full_name ?? 'Học sinh',
          pickup_stop_id: att.check_in_stop_id ?? null,
          pickup_stop_name: 'Điểm đón trên tuyến',
          check_in_time: att.check_in_time,
          check_out_time: att.check_out_time,
          detection_method: att.detection_method,
          ai_confidence: att.ai_confidence ? Number(att.ai_confidence) : null,
          status: att.status,
        })
      }
    }

    return Array.from(uniqueStudentsMap.values())
  },

  // 3. Thống kê tổng quan 4 thẻ KPI & Tiến độ theo tuyến của đúng ngày đang xem
  async getDailyOverview(trips: TripOption[]): Promise<{
    summary: AttendanceSummary
    routeProgress: RouteProgressItem[]
  }> {
    const { data: routesData } = await supabase
      .from('routes')
      .select('route_id, route_name')
      .eq('status', 'ACTIVE')
      .order('route_code')

    const { data: allStudentRoutes } = await supabase
      .from('student_routes')
      .select('student_id, route_id')
      .eq('status', 'ACTIVE')

    const tripIds = trips.map((t) => t.trip_id)
    const { data: allAttendances } =
      tripIds.length > 0
        ? await supabase
            .from('attendance')
            .select('trip_id, student_id, status, detection_method')
            .in('trip_id', tripIds)
        : { data: [] }

    const srList = allStudentRoutes ?? []
    const attList = allAttendances ?? []

    // Tiến độ từng tuyến trong ngày đang xem
    const routeProgress: RouteProgressItem[] = (routesData ?? []).map((r) => {
      const routeTrips = trips.filter((t) => t.route_id === r.route_id)
      const studentsOnRoute = srList.filter((sr) => sr.route_id === r.route_id).length
      // Tổng lượt dự kiến = số học sinh trên tuyến x số chuyến của tuyến trong ngày (sáng + chiều)
      const totalExpectedOnRoute =
        routeTrips.length > 0 ? studentsOnRoute * routeTrips.length : studentsOnRoute

      const routeTripIds = new Set(routeTrips.map((t) => t.trip_id))
      const boardedOnRoute = attList.filter(
        (a) =>
          routeTripIds.has(a.trip_id) &&
          (a.status === 'BOARDED' || a.status === 'ALIGHTED')
      ).length

      return {
        route_id: r.route_id,
        route_name: r.route_name,
        boarded_count: boardedOnRoute,
        total_count: totalExpectedOnRoute,
      }
    })

    // Tổng dự kiến = tổng học sinh trên tất cả các chuyến trong ngày (cả đón và trả)
    const expectedToday = trips.reduce((sum, trip) => {
      const countInRoute = srList.filter((sr) => sr.route_id === trip.route_id).length
      return sum + countInRoute
    }, 0)

    const boardedRecords = attList.filter(
      (a) => a.status === 'BOARDED' || a.status === 'ALIGHTED'
    )
    const boardedCount = boardedRecords.length
    const aiBoardedCount = boardedRecords.filter(
      (a) => a.detection_method === 'AI'
    ).length
    const absentCount = attList.filter((a) => a.status === 'ABSENT').length
    const pendingCount = Math.max(0, expectedToday - boardedCount - absentCount)

    const aiRate =
      boardedCount > 0 ? Math.round((aiBoardedCount / boardedCount) * 100) : 0

    return {
      summary: {
        expected_today: expectedToday,
        boarded_today: boardedCount,
        ai_rate: aiRate,
        pending_today: pendingCount,
        absent_today: absentCount,
      },
      routeProgress,
    }
  },

  // 4. Điểm danh tay (Check-in thủ công cho học sinh chưa lên xe)
  async manualCheckIn(
    tripId: string,
    studentId: string,
    pickupStopId: string | null
  ) {
    const { data: sessionData } = await supabase.auth.getSession()
    const recorderId = sessionData.session?.user?.id ?? null

    const { error } = await supabase.from('attendance').upsert(
      {
        trip_id: tripId,
        student_id: studentId,
        check_in_time: new Date().toISOString(),
        check_in_stop_id: pickupStopId,
        detection_method: 'MANUAL',
        ai_confidence: null,
        recorded_by: recorderId,
        status: 'BOARDED',
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'trip_id,student_id' }
    )

    if (error) throw error
  },

  // 5. Chốt chuyến (Hoàn thành chuyến xe khi lượt lên == lượt xuống)
  async completeTrip(tripId: string) {
    const { error } = await supabase
      .from('trips')
      .update({
        status: 'COMPLETED',
        updated_at: new Date().toISOString(),
      })
      .eq('trip_id', tripId)

    if (error) throw error
  },
}