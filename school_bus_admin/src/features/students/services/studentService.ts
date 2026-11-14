import { supabase } from '@/lib/supabase'
import type { ChildRequest, FaceStatus, StudentRow } from '../types'

const REQUIRED_ANGLES = 3 // nhìn thẳng, quay trái, quay phải

interface LinkRow {
  student_id: string
  parent_id: string
  relationship: string
  verification_status: string
  parent_name: string | null
  parent_phone: string | null
  parent_email: string | null
  student_code: string | null
  student_name: string | null
  date_of_birth: string | null
  gender: string | null
  class_name: string | null
  student_status: string | null
}

const first = <T,>(x: T | T[] | null | undefined): T | undefined =>
  Array.isArray(x) ? x[0] : (x ?? undefined)

function maskPhone(p?: string | null): string {
  if (!p) return '—'
  const d = p.replace(/\D/g, '')
  return d.length < 6 ? p : `${d.slice(0, 2)}•• ••• ${d.slice(-3)}`
}

function faceStatusOf(valid: number, total: number): FaceStatus {
  if (valid >= REQUIRED_ANGLES) return 'REGISTERED'
  if (total > 0) return 'NEEDS_UPDATE'
  return 'NONE'
}

async function fetchLinks(): Promise<LinkRow[]> {
  const { data, error } = await supabase.rpc('admin_parent_links')
  if (error) throw new Error(error.message)
  return (data ?? []) as LinkRow[]
}

export const studentService = {
  /** Danh sách học sinh đang hoạt động. Phụ huynh chỉ tính khi đã được duyệt (APPROVED). */
  async getStudents(): Promise<StudentRow[]> {
    const [studentsRes, routeLinksRes, routesRes, links, faceRes] = await Promise.all([
      supabase
        .from('students')
        .select('student_id, student_code, full_name, class_name, avatar_url')
        .eq('status', 'ACTIVE') // ẩn em chưa duyệt / đã ngừng
        .order('full_name'),

      supabase
        .from('student_routes')
        .select(`
          student_id,
          route_id,
          pickup_stop:route_stops!student_routes_route_id_pickup_stop_id_fkey ( stop_name )
        `)
        .eq('status', 'ACTIVE'),

      supabase.from('routes').select('route_id, route_code'),
      fetchLinks(),
      supabase.rpc('admin_face_summary'),
    ])

    for (const res of [studentsRes, routeLinksRes, routesRes, faceRes]) {
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

    const parentByStudent = new Map<string, { name: string; phone: string }>()
    for (const l of links) {
      if (l.verification_status !== 'APPROVED' || parentByStudent.has(l.student_id)) continue
      parentByStudent.set(l.student_id, {
        name: l.parent_name ?? '—',
        phone: l.parent_phone ?? '',
      })
    }

    const faceByStudent = new Map(
      ((faceRes.data ?? []) as { student_id: string; valid_count: number; total_count: number }[])
        .map((f) => [f.student_id, f]),
    )

    return (studentsRes.data ?? []).map((s): StudentRow => {
      const face = faceByStudent.get(s.student_id)
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
        hasParent: !!parent,
        routeCode: route?.code ?? '—',
        pickupStop: route?.stop ?? '—',
        faceStatus: faceStatusOf(face?.valid_count ?? 0, face?.total_count ?? 0),
        faceCount: face?.valid_count ?? 0,
      }
    })
  },

  /** Các đăng ký đang chờ nhà trường duyệt. */
  async getChildRequests(): Promise<ChildRequest[]> {
    const links = await fetchLinks()
    return links
      .filter((l) => l.verification_status === 'PENDING')
      .map((l): ChildRequest => ({
        studentId: l.student_id,
        parentId: l.parent_id,
        studentCode: l.student_code ?? '',
        fullName: l.student_name ?? '',
        dateOfBirth: l.date_of_birth,
        gender: l.gender,
        className: l.class_name ?? '',
        relationship: l.relationship,
        parentName: l.parent_name ?? '—',
        parentPhone: l.parent_phone ?? '',
        parentEmail: l.parent_email ?? '',
      }))
  },

  async reviewRequest(p: {
    studentId: string
    parentId: string
    approve: boolean
    mergeIntoId?: string
    note?: string
  }) {
    const { error } = await supabase.rpc('admin_review_child_link', {
      p_student_id: p.studentId,
      p_parent_id: p.parentId,
      p_approve: p.approve,
      p_merge_into: p.mergeIntoId ?? null,
      p_note: p.note ?? null,
    })
    if (error) throw new Error(error.message)
  },
}