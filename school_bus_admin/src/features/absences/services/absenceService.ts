
import { supabase } from '@/lib/supabase'

import type {
  AbsenceRequest,
  AbsenceSession,
  AbsenceStatus,
  AbsenceStats,
} from '../types'

// ========================================
// DATABASE TYPES
// ========================================

interface AbsenceRow {
  absence_id: string
  student_id: string
  parent_id: string
  absence_date: string
  session: AbsenceSession
  reason: string
  status: AbsenceStatus
  rejection_note: string | null
  created_at: string
  reviewed_at: string | null
}

interface StudentRow {
  student_id: string
  full_name: string
  class_name: string | null
}

interface ParentRow {
  parent_id: string
  user_id: string
}

interface UserRow {
  user_id: string
  full_name: string
}

interface StudentRouteRow {
  student_id: string
  route_id: string
  status: string
  effective_from: string
  effective_to: string | null
}

interface RouteRow {
  route_id: string
  route_code: string
  route_name: string
}

// ========================================
// GET ABSENCES
// ========================================

export async function getAbsences(): Promise<AbsenceRequest[]> {
  // 1. Lấy danh sách đơn xin nghỉ
  const { data: absenceData, error: absenceError } = await supabase
    .from('absences')
    .select(`
      absence_id,
      student_id,
      parent_id,
      absence_date,
      session,
      reason,
      status,
      rejection_note,
      created_at,
      reviewed_at
    `)
    .order('created_at', { ascending: false })

  if (absenceError) {
    console.error('getAbsences - absences:', absenceError)
    throw new Error(`Không thể lấy danh sách đơn nghỉ: ${absenceError.message}`)
  }

  const absences = (absenceData ?? []) as AbsenceRow[]

  if (absences.length === 0) {
    return []
  }

  // 2. Lấy danh sách ID học sinh và phụ huynh
  const studentIds = [
    ...new Set(absences.map((item) => item.student_id)),
  ]

  const parentIds = [
    ...new Set(absences.map((item) => item.parent_id)),
  ]

  // 3. Lấy thông tin học sinh
  const { data: studentData, error: studentError } = await supabase
    .from('students')
    .select(`
      student_id,
      full_name,
      class_name
    `)
    .in('student_id', studentIds)

  if (studentError) {
    console.error('getAbsences - students:', studentError)
    throw new Error(`Không thể lấy thông tin học sinh: ${studentError.message}`)
  }

  const students = (studentData ?? []) as StudentRow[]

  const studentMap = new Map(
    students.map((student) => [
      student.student_id,
      student,
    ]),
  )

  // 4. Lấy thông tin phụ huynh
  const { data: parentData, error: parentError } = await supabase
    .from('parents')
    .select(`
      parent_id,
      user_id
    `)
    .in('parent_id', parentIds)

  if (parentError) {
    console.error('getAbsences - parents:', parentError)
    throw new Error(`Không thể lấy thông tin phụ huynh: ${parentError.message}`)
  }

  const parents = (parentData ?? []) as ParentRow[]

  const parentMap = new Map(
    parents.map((parent) => [
      parent.parent_id,
      parent.user_id,
    ]),
  )

  // 5. Lấy tên phụ huynh từ bảng users
  const userIds = [
    ...new Set(parents.map((parent) => parent.user_id)),
  ]

  let users: UserRow[] = []

  if (userIds.length > 0) {
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select(`
        user_id,
        full_name
      `)
      .in('user_id', userIds)

    if (userError) {
      console.error('getAbsences - users:', userError)
      throw new Error(`Không thể lấy tên phụ huynh: ${userError.message}`)
    }

    users = (userData ?? []) as UserRow[]
  }

  const userMap = new Map(
    users.map((user) => [
      user.user_id,
      user.full_name,
    ]),
  )

  // 6. Lấy phân tuyến học sinh
  const { data: studentRouteData, error: studentRouteError } =
    await supabase
      .from('student_routes')
      .select(`
        student_id,
        route_id,
        status,
        effective_from,
        effective_to
      `)
      .in('student_id', studentIds)
      .eq('status', 'ACTIVE')

  if (studentRouteError) {
    console.error('getAbsences - student_routes:', studentRouteError)
    throw new Error(`Không thể lấy thông tin phân tuyến: ${studentRouteError.message}`)
  }

  const studentRoutes = (studentRouteData ?? []) as StudentRouteRow[]

  // 7. Lấy thông tin tuyến xe
  const routeIds = [
    ...new Set(studentRoutes.map((item) => item.route_id)),
  ]

  let routes: RouteRow[] = []

  if (routeIds.length > 0) {
    const { data: routeData, error: routeError } = await supabase
      .from('routes')
      .select(`
        route_id,
        route_code,
        route_name
      `)
      .in('route_id', routeIds)

    if (routeError) {
      console.error('getAbsences - routes:', routeError)
      throw new Error(`Không thể lấy thông tin tuyến xe: ${routeError.message}`)
    }

    routes = (routeData ?? []) as RouteRow[]
  }

  const routeMap = new Map(
    routes.map((route) => [
      route.route_id,
      route,
    ]),
  )

  // 8. Tìm tuyến xe phù hợp với ngày nghỉ
  const getRouteInfo = (
    studentId: string,
    absenceDate: string,
  ): string => {
    const matchedRoutes = studentRoutes
      .filter((item) => {
        const sameStudent = item.student_id === studentId
        const validFrom = item.effective_from <= absenceDate

        const validTo =
          !item.effective_to ||
          item.effective_to >= absenceDate

        return sameStudent && validFrom && validTo
      })
      .sort((a, b) =>
        b.effective_from.localeCompare(a.effective_from),
      )

    const matchedRoute = matchedRoutes[0]

    if (!matchedRoute) {
      return 'Chưa có tuyến xe'
    }

    const route = routeMap.get(matchedRoute.route_id)

    if (!route) {
      return 'Chưa có thông tin tuyến'
    }

    return `${route.route_code} - ${route.route_name}`
  }

  // 9. Ghép dữ liệu từ các bảng
  return absences.map((absence) => {
    const student = studentMap.get(absence.student_id)

    const parentUserId = parentMap.get(absence.parent_id)

    const parentName = parentUserId
      ? userMap.get(parentUserId)
      : undefined

    return {
      id: absence.absence_id,
      studentId: absence.student_id,
      parentId: absence.parent_id,

      studentName:
        student?.full_name ?? 'Không tìm thấy học sinh',

      studentClass:
        student?.class_name ?? 'Chưa cập nhật lớp',

      parentName:
        parentName ?? 'Không tìm thấy phụ huynh',

      date: absence.absence_date,
      session: absence.session,
      reason: absence.reason,

      status: absence.status,
      submittedAt: absence.created_at,
      reviewedAt: absence.reviewed_at,
      rejectionNote: absence.rejection_note,

      routeInfo: getRouteInfo(
        absence.student_id,
        absence.absence_date,
      ),
    }
  })
}

// ========================================
// UPDATE ABSENCE STATUS
// ========================================

export async function updateAbsenceStatus(
  absenceId: string,
  status: 'APPROVED' | 'REJECTED',
  rejectionNote?: string,
): Promise<void> {
  // 1. Kiểm tra người dùng đăng nhập
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser()

  if (authError) {
    throw new Error(authError.message)
  }

  if (!user) {
    throw new Error('Bạn cần đăng nhập để xử lý đơn.')
  }

  // 2. Kiểm tra lý do từ chối
  if (status === 'REJECTED' && !rejectionNote?.trim()) {
    throw new Error('Vui lòng nhập lý do từ chối đơn.')
  }

  // 3. Cập nhật trạng thái đơn
  const { data, error } = await supabase
    .from('absences')
    .update({
      status,
      reviewed_by: user.id,
      reviewed_at: new Date().toISOString(),
      rejection_note:
        status === 'REJECTED'
          ? rejectionNote!.trim()
          : null,
    })
    .eq('absence_id', absenceId)
    .eq('status', 'PENDING')
    .select('absence_id')
    .maybeSingle()

  if (error) {
    console.error('updateAbsenceStatus:', error)
    throw new Error(`Không thể cập nhật đơn nghỉ: ${error.message}`)
  }

  if (!data) {
    throw new Error(
      'Đơn không tồn tại hoặc đã được xử lý trước đó.',
    )
  }
}

// ========================================
// CALCULATE STATISTICS
// ========================================

export function calculateAbsenceStats(
  requests: AbsenceRequest[],
): AbsenceStats {
  const today = new Date()

  const todayString = [
    today.getFullYear(),
    String(today.getMonth() + 1).padStart(2, '0'),
    String(today.getDate()).padStart(2, '0'),
  ].join('-')

  // Đếm học sinh có đơn nghỉ đã được duyệt hôm nay
  const absentStudentIds = new Set(
    requests
      .filter(
        (item) =>
          item.status === 'APPROVED' &&
          item.date.slice(0, 10) === todayString,
      )
      .map((item) => item.studentId),
  )

  return {
    pending: requests.filter(
      (item) => item.status === 'PENDING',
    ).length,

    approved: requests.filter(
      (item) => item.status === 'APPROVED',
    ).length,

    rejected: requests.filter(
      (item) => item.status === 'REJECTED',
    ).length,

    absentToday: absentStudentIds.size,
  }
}
