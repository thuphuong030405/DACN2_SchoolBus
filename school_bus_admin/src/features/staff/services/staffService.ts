// Đổi dòng đầu tiên của staffService.ts thành:
import { supabase, supabaseSignupClient } from '@/lib/supabase'
import type { DocStatus, StaffFormPayload, StaffMember } from '../types'

function evaluateExpiry(dateStr?: string | null): { label: string; status: DocStatus } {
  if (!dateStr) {
    return { label: 'Còn hiệu lực', status: 'VALID' }
  }
  const expiry = new Date(dateStr)
  const now = new Date()
  const diffDays = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

  const month = String(expiry.getMonth() + 1).padStart(2, '0')
  const year = expiry.getFullYear()
  const formatted = `Hạn ${month}/${year}`

  if (diffDays < 0) return { label: formatted, status: 'EXPIRED' }
  if (diffDays <= 30) return { label: formatted, status: 'EXPIRING_SOON' }
  return { label: formatted, status: 'VALID' }
}

export const staffService = {
  async getAllStaff(): Promise<StaffMember[]> {
    // 1. Lấy danh sách tài xế kèm thông tin user
    const { data: driversData, error: driverErr } = await supabase
      .from('drivers')
      .select(`
        driver_id,
        user_id,
        driver_code,
        license_number,
        license_expiry,
        users!inner (
          full_name,
          phone,
          email,
          avatar_url,
          is_active
        )
      `)
      .order('driver_code')

    if (driverErr) throw driverErr

    // 2. Lấy danh sách bảo mẫu (teachers) kèm thông tin user
    const { data: teachersData, error: teacherErr } = await supabase
      .from('teachers')
      .select(`
        teacher_id,
        user_id,
        teacher_code,
        department,
        users!inner (
          full_name,
          phone,
          email,
          avatar_url,
          is_active
        )
      `)
      .order('teacher_code')

    if (teacherErr) throw teacherErr

    // 3. Lấy danh sách chuyến xe để xác định trạng thái đang chạy, xe/tuyến phụ trách và tổng số chuyến
    const { data: tripsData, error: tripErr } = await supabase
      .from('trips')
      .select(`
        trip_id,
        driver_id,
        teacher_id,
        status,
        trip_date,
        buses ( bus_id, license_plate ),
        routes ( route_id, route_name ),
        drivers ( users ( full_name ) ),
        teachers ( users ( full_name ) )
      `)
      .order('start_at', { ascending: false })

    if (tripErr) throw tripErr

    const trips = tripsData ?? []

    // Chuẩn hóa dữ liệu Tài xế
    const mappedDrivers: StaffMember[] = (driversData ?? []).map((d: any) => {
      const user = Array.isArray(d.users) ? d.users[0] : d.users
      const myTrips = trips.filter((t) => t.driver_id === d.driver_id)
      const activeTrip =
        myTrips.find((t) => t.status === 'IN_PROGRESS') ||
        myTrips.find((t) => t.status === 'SCHEDULED') ||
        myTrips[0]

      const isRunning = myTrips.some((t) => t.status === 'IN_PROGRESS')
      const docInfo = evaluateExpiry(d.license_expiry)

      const busObj = activeTrip?.buses as any
      const routeObj = activeTrip?.routes as any
      const partnerUser = (activeTrip?.teachers as any)?.users

      return {
        id: d.driver_id,
        user_id: d.user_id,
        code: d.driver_code,
        full_name: user?.full_name ?? 'Chưa cập nhật',
        phone: user?.phone ?? null,
        email: user?.email ?? '',
        avatar_url: user?.avatar_url ?? null,
        role: 'DRIVER',
        is_active: user?.is_active ?? true,
        license_number: d.license_number,
        license_expiry: d.license_expiry,
        assigned_bus_id: busObj?.bus_id ?? null,
        assigned_bus_plate: busObj?.license_plate ?? null,
        assigned_route_id: routeObj?.route_id ?? null,
        assigned_route_name: routeObj?.route_name ?? null,
        partner_name: partnerUser?.full_name ? `Cô ${partnerUser.full_name.split(' ').pop()}` : 'Chưa phân công',
        status: !user?.is_active ? 'INACTIVE' : isRunning ? 'RUNNING' : 'READY',
        total_trips: myTrips.filter((t) => t.status === 'COMPLETED').length || myTrips.length,
        incidents_count: 0,
        on_time_rate: 97,
        primary_doc_title: 'GPLX hạng D',
        primary_doc_expiry: docInfo.label,
        primary_doc_status: docInfo.status,
        documents: [
          {
            name: 'Giấy phép lái xe hạng D',
            expiryLabel: docInfo.label,
            status: docInfo.status,
          },
          {
            name: 'Khám sức khỏe định kỳ',
            expiryLabel: 'Hạn 12/2026',
            status: 'EXPIRING_SOON',
          },
          {
            name: 'Tập huấn an toàn trẻ em',
            expiryLabel: 'Còn hiệu lực',
            status: 'VALID',
          },
        ],
      }
    })

    // Chuẩn hóa dữ liệu Bảo mẫu (Teachers)
    const mappedTeachers: StaffMember[] = (teachersData ?? []).map((t: any) => {
      const user = Array.isArray(t.users) ? t.users[0] : t.users
      const myTrips = trips.filter((tr) => tr.teacher_id === t.teacher_id)
      const activeTrip =
        myTrips.find((tr) => tr.status === 'IN_PROGRESS') ||
        myTrips.find((tr) => tr.status === 'SCHEDULED') ||
        myTrips[0]

      const isRunning = myTrips.some((tr) => tr.status === 'IN_PROGRESS')
      const busObj = activeTrip?.buses as any
      const routeObj = activeTrip?.routes as any
      const partnerUser = (activeTrip?.drivers as any)?.users

      return {
        id: t.teacher_id,
        user_id: t.user_id,
        code: t.teacher_code,
        full_name: user?.full_name ?? 'Chưa cập nhật',
        phone: user?.phone ?? null,
        email: user?.email ?? '',
        avatar_url: user?.avatar_url ?? null,
        role: 'TEACHER',
        is_active: user?.is_active ?? true,
        department: t.department,
        assigned_bus_id: busObj?.bus_id ?? null,
        assigned_bus_plate: busObj?.license_plate ?? null,
        assigned_route_id: routeObj?.route_id ?? null,
        assigned_route_name: routeObj?.route_name ?? null,
        partner_name: partnerUser?.full_name ?? 'Chưa phân công',
        status: !user?.is_active ? 'INACTIVE' : isRunning ? 'RUNNING' : 'READY',
        total_trips: myTrips.filter((tr) => tr.status === 'COMPLETED').length || myTrips.length,
        incidents_count: 0,
        on_time_rate: 99,
        primary_doc_title: 'Sơ cấp cứu',
        primary_doc_expiry: 'Hạn 06/2027',
        primary_doc_status: 'VALID',
        documents: [
          {
            name: 'Chứng chỉ sơ cấp cứu',
            expiryLabel: 'Hạn 06/2027',
            status: 'VALID',
          },
          {
            name: 'Khám sức khỏe định kỳ',
            expiryLabel: 'Hạn 12/2026',
            status: 'EXPIRING_SOON',
          },
          {
            name: 'Tập huấn an toàn trẻ em',
            expiryLabel: 'Còn hiệu lực',
            status: 'VALID',
          },
        ],
      }
    })

    return [...mappedDrivers, ...mappedTeachers]
  },

  async updateStaff(staff: StaffMember, payload: Partial<StaffFormPayload>) {
    // Cập nhật bảng users
    const { error: userError } = await supabase
      .from('users')
      .update({
        full_name: payload.full_name,
        phone: payload.phone,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', staff.user_id)

    if (userError) throw userError

    // Cập nhật bảng chuyên môn tương ứng
    if (staff.role === 'DRIVER') {
      const { error } = await supabase
        .from('drivers')
        .update({
          driver_code: payload.code,
          license_number: payload.license_number,
          license_expiry: payload.license_expiry || null,
          updated_at: new Date().toISOString(),
        })
        .eq('driver_id', staff.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('teachers')
        .update({
          teacher_code: payload.code,
          department: payload.department || null,
          updated_at: new Date().toISOString(),
        })
        .eq('teacher_id', staff.id)
      if (error) throw error
    }
  },

  async createStaff(payload: StaffFormPayload) {
    // Tạo user thông qua Supabase Auth SignUp hoặc RPC/Edge Function
    const { data: authData, error: authErr } = await supabaseSignupClient.auth.signUp({
      email: payload.email,
      password: 'BusAnToan@2026', // Mật khẩu mặc định khi admin tạo
      options: {
        data: {
          full_name: payload.full_name,
          role: payload.role,
        },
      },
    })

    if (authErr) throw authErr
    if (!authData.user) throw new Error('Không thể tạo tài khoản người dùng')

    const userId = authData.user.id

    const { error: userErr } = await supabase.from('users').upsert({
      user_id: userId,
      full_name: payload.full_name,
      email: payload.email,
      phone: payload.phone || null,
      role: payload.role,
      is_active: true,
    })

    if (userErr) throw userErr

    if (payload.role === 'DRIVER') {
      const { error } = await supabase.from('drivers').insert({
        user_id: userId,
        driver_code: payload.code,
        license_number: payload.license_number || `GPLX-${Date.now()}`,
        license_expiry: payload.license_expiry || null,
      })
      if (error) throw error
    } else {
      const { error } = await supabase.from('teachers').insert({
        user_id: userId,
        teacher_code: payload.code,
        department: payload.department || 'Tổ Bảo mẫu',
      })
      if (error) throw error
    }
  },
  async reassignTrip(
    staff: StaffMember,
    busId: string,
    routeId: string,
    partnerId: string
  ) {
    const column = staff.role === 'DRIVER' ? 'driver_id' : 'teacher_id'
    const partnerColumn = staff.role === 'DRIVER' ? 'teacher_id' : 'driver_id'

    // Kiểm tra nhân sự đã có chuyến SCHEDULED / IN_PROGRESS chưa
    const { data: existingTrips, error: fetchErr } = await supabase
      .from('trips')
      .select('trip_id')
      .eq(column, staff.id)
      .in('status', ['SCHEDULED', 'IN_PROGRESS'])

    if (fetchErr) throw fetchErr

    if (existingTrips && existingTrips.length > 0) {
      // Đã có chuyến -> Cập nhật xe, tuyến và người đi cùng
      const { error } = await supabase
        .from('trips')
        .update({
          bus_id: busId,
          route_id: routeId,
          [partnerColumn]: partnerId,
          updated_at: new Date().toISOString(),
        })
        .eq(column, staff.id)
        .in('status', ['SCHEDULED', 'IN_PROGRESS'])

      if (error) throw error
    } else {
      // Nhân sự mới chưa có chuyến -> Tạo chuyến SCHEDULED mới (theo múi giờ VN +07:00)
      const vnDateStr = new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Asia/Ho_Chi_Minh',
      }).format(new Date())

      const { error: insertErr } = await supabase.from('trips').insert({
        bus_id: busId,
        route_id: routeId,
        driver_id: staff.role === 'DRIVER' ? staff.id : partnerId,
        teacher_id: staff.role === 'TEACHER' ? staff.id : partnerId,
        trip_date: vnDateStr,
        trip_type: 'MORNING',
        start_at: `${vnDateStr}T06:30:00+07:00`,
        end_at: `${vnDateStr}T07:45:00+07:00`,
        status: 'SCHEDULED',
      })

      if (insertErr) throw insertErr
    }
  },
}
//   async reassignTrip(staff: StaffMember, busId: string, routeId: string) {
//     // Cập nhật các chuyến SCHEDULED sắp tới của nhân sự này sang xe/tuyến mới
//     const column = staff.role === 'DRIVER' ? 'driver_id' : 'teacher_id'

//     const { error } = await supabase
//       .from('trips')
//       .update({
//         bus_id: busId,
//         route_id: routeId,
//         updated_at: new Date().toISOString(),
//       })
//       .eq(column, staff.id)
//       .in('status', ['SCHEDULED', 'IN_PROGRESS'])

//     if (error) throw error
//   },
// }
