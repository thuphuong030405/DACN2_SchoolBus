
import { supabase } from '@/lib/supabase'

export type TripType = 'MORNING' | 'AFTERNOON'

export interface TripFormData {
  bus_id: string
  route_id: string
  driver_id: string
  teacher_id: string
  trip_date: string
  trip_type: TripType
}

export interface TripFormOptions {
  buses: Array<{
    bus_id: string
    bus_code: string
    license_plate: string
  }>
  routes: Array<{
    route_id: string
    route_code: string
    route_name: string
  }>
  drivers: Array<{
    driver_id: string
    driver_code: string
    full_name: string
  }>
  teachers: Array<{
    teacher_id: string
    teacher_code: string
    full_name: string
  }>
}

type StaffRow = {
  driver_id?: string
  teacher_id?: string
  driver_code?: string
  teacher_code?: string
  users:
    | { full_name: string | null }
    | { full_name: string | null }[]
    | null
}

function getUserFullName(
  users: StaffRow['users'],
): string {
  if (Array.isArray(users)) {
    return users[0]?.full_name ?? ''
  }

  return users?.full_name ?? ''
}

export async function getTripFormOptions(): Promise<TripFormOptions> {
  const [
    busesResult,
    routesResult,
    driversResult,
    teachersResult,
  ] = await Promise.all([
    supabase
      .from('buses')
      .select('bus_id, bus_code, license_plate')
      .eq('status', 'ACTIVE')
      .order('bus_code'),

    supabase
      .from('routes')
      .select('route_id, route_code, route_name')
      .eq('status', 'ACTIVE')
      .order('route_name'),

    supabase
      .from('drivers')
      .select(`
        driver_id,
        driver_code,
        users (
          full_name
        )
      `)
      .order('driver_code'),

    supabase
      .from('teachers')
      .select(`
        teacher_id,
        teacher_code,
        users (
          full_name
        )
      `)
      .order('teacher_code'),
  ])

  if (busesResult.error) {
    throw new Error(`Không tải được danh sách xe: ${busesResult.error.message}`)
  }

  if (routesResult.error) {
    throw new Error(`Không tải được danh sách tuyến: ${routesResult.error.message}`)
  }

  if (driversResult.error) {
    throw new Error(`Không tải được danh sách tài xế: ${driversResult.error.message}`)
  }

  if (teachersResult.error) {
    throw new Error(`Không tải được danh sách giáo viên: ${teachersResult.error.message}`)
  }

  const drivers = (driversResult.data ?? []) as unknown as StaffRow[]
  const teachers = (teachersResult.data ?? []) as unknown as StaffRow[]

  return {
    buses: busesResult.data ?? [],
    routes: routesResult.data ?? [],

    drivers: drivers.map((item) => ({
      driver_id: item.driver_id!,
      driver_code: item.driver_code ?? '',
      full_name:
        getUserFullName(item.users) ||
        item.driver_code ||
        'Chưa có tên tài xế',
    })),

    teachers: teachers.map((item) => ({
      teacher_id: item.teacher_id!,
      teacher_code: item.teacher_code ?? '',
      full_name:
        getUserFullName(item.users) ||
        item.teacher_code ||
        'Chưa có tên giáo viên',
    })),
  }
}

export async function createTrip(input: TripFormData) {
  // Kiểm tra dữ liệu bắt buộc trước khi gửi lên Supabase.
  if (
    !input.bus_id ||
    !input.route_id ||
    !input.driver_id ||
    !input.teacher_id ||
    !input.trip_date
  ) {
    throw new Error('Vui lòng nhập đầy đủ thông tin chuyến xe.')
  }

  // Kiểm tra xe đã có chuyến cùng buổi trong ngày chưa.
  const { data: existingTrip, error: checkError } = await supabase
    .from('trips')
    .select('trip_id, status')
    .eq('bus_id', input.bus_id)
    .eq('trip_date', input.trip_date)
    .eq('trip_type', input.trip_type)
    .in('status', ['SCHEDULED', 'IN_PROGRESS'])
    .limit(1)
    .maybeSingle()

  if (checkError) {
    throw new Error(`Không kiểm tra được lịch xe: ${checkError.message}`)
  }

  if (existingTrip) {
    throw new Error('Xe này đã có chuyến trong cùng buổi và ngày đã chọn.')
  }

  // Ghi chuyến mới trực tiếp vào bảng trips.
  const { data, error } = await supabase
    .from('trips')
    .insert({
      bus_id: input.bus_id,
      route_id: input.route_id,
      driver_id: input.driver_id,
      teacher_id: input.teacher_id,
      trip_date: input.trip_date,
      trip_type: input.trip_type,
      status: 'SCHEDULED',
    })
    .select(`
      trip_id,
      bus_id,
      route_id,
      driver_id,
      teacher_id,
      trip_date,
      trip_type,
      status,
      created_at
    `)
    .single()

  if (error) {
    console.error('Supabase createTrip error:', error)
    throw new Error(`Không thể lưu chuyến xe: ${error.message}`)
  }

  return data
}
