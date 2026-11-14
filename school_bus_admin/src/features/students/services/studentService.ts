import { supabase } from '@/lib/supabase'
import type { FaceStatus, StudentRow } from '../types'

const REQUIRED_ANGLES = 3 // nhìn thẳng, quay trái, quay phải

const first = <T,>(x: T | T[] | null | undefined): T | undefined =>
  Array.isArray(x) ? x[0] : (x ?? undefined)

function maskPhone(p?: string | null): string {
  if (!p) return '—'
  const d = p.replace(/\D/g, '')
  return d.length < 6 ? p : `${d.slice(0, 2)}•• ••• ${d.slice(-3)}`
}

function faceStatusOf(valid: number, total: number): FaceStatus {
  if (valid >= REQUIRED_ANGLES) return 'REGISTERED'
  if (total > 0) return 'NEEDS_UPDATE' // thiếu góc, sai mô hình hoặc bị vô hiệu
  return 'NONE'
}

export const studentService = {
  /** Trường có vài trăm học sinh nên lấy hết, lọc và phân trang ở trình duyệt. */
  async getStudents(): Promise<StudentRow[]> {
    const [studentsRes, routeLinksRes, routesRes, parentLinksRes, usersRes, faceRes] =
      await Promise.all([
        supabase
          .from('students')
          .select('student_id, student_code, full_name, class_name, avatar_url')
          .order('full_name'),

        // Tuyến + điểm đón (cùng khóa ngoại với trang Điểm danh)
        supabase
          .from('student_routes')
          .select(`
            student_id,
            route_id,
            pickup_stop:route_stops!student_routes_route_id_pickup_stop_id_fkey ( stop_name )
          `)
          .eq('status', 'ACTIVE'),

        supabase.from('routes').select('route_id, route_code'),

        supabase.from('student_parents').select('student_id, parents ( user_id )'),

        // Nếu giá trị role của phụ huynh không phải 'PARENT', sửa ở đây
        supabase
          .from('users')
          .select('user_id, full_name, phone')
          .eq('role', 'PARENT'),

        supabase.rpc('admin_face_summary'),
      ])

    for (const res of [studentsRes, routeLinksRes, routesRes, parentLinksRes, usersRes, faceRes]) {
      if (res.error) throw new Error(res.error.message)
    }

    const routeCodeById = new Map(
      (routesRes.data ?? []).map((r) => [r.route_id as string, r.route_code as string]),
    )

    const routeByStudent = new Map<string, { code: string; stop: string }>()
    for (const l of routeLinksRes.data ?? []) {
      if (routeByStudent.has(l.student_id)) continue
      const stop = first(l.pickup_stop as { stop_name: string } | { stop_name: string }[] | null)
      routeByStudent.set(l.student_id, {
        code: routeCodeById.get(l.route_id) ?? '—',
        stop: stop?.stop_name ?? '—',
      })
    }

    const userById = new Map(
      (usersRes.data ?? []).map((u) => [u.user_id as string, u]),
    )

    const parentByStudent = new Map<string, { name: string; phone: string }>()
    for (const l of parentLinksRes.data ?? []) {
      if (parentByStudent.has(l.student_id)) continue
      const p = first(l.parents as { user_id: string } | { user_id: string }[] | null)
      const u = p ? userById.get(p.user_id) : undefined
      if (u) parentByStudent.set(l.student_id, { name: u.full_name, phone: u.phone })
    }

    const faceByStudent = new Map(
      ((faceRes.data ?? []) as { student_id: string; valid_count: number; total_count: number }[])
        .map((f) => [f.student_id, f]),
    )

    return (studentsRes.data ?? []).map((s): StudentRow => {
      const face = faceByStudent.get(s.student_id)
      const valid = face?.valid_count ?? 0
      const route = routeByStudent.get(s.student_id)
      const parent = parentByStudent.get(s.student_id)
      return {
        id: s.student_id,
        code: s.student_code ?? '',
        fullName: s.full_name ?? '',
        className: s.class_name ?? '',
        avatarUrl: s.avatar_url ?? null,
        parentName: parent?.name ?? '—',
        parentPhone: maskPhone(parent?.phone),
        routeCode: route?.code ?? '—',
        pickupStop: route?.stop ?? '—',
        faceStatus: faceStatusOf(valid, face?.total_count ?? 0),
        faceCount: valid,
      }
    })
  },
}