export type StaffRole = 'DRIVER' | 'TEACHER'
export type StaffStatus = 'RUNNING' | 'READY' | 'INACTIVE'
export type DocStatus = 'VALID' | 'EXPIRING_SOON' | 'EXPIRED'

export interface StaffDocument {
  name: string
  expiryLabel: string
  status: DocStatus
}

export interface StaffMember {
  id: string               // driver_id hoặc teacher_id
  user_id: string
  code: string             // TX-014 hoặc BM-006 (teacher_code)
  full_name: string
  phone: string | null
  email: string
  avatar_url: string | null
  role: StaffRole
  is_active: boolean

  // Thông tin chuyên môn
  license_number?: string | null
  license_expiry?: string | null
  department?: string | null

  // Thông tin phân công hiện tại (lấy từ bảng trips)
  assigned_bus_id?: string | null
  assigned_bus_plate?: string | null
  assigned_route_id?: string | null
  assigned_route_name?: string | null
  partner_name?: string | null      // Bảo mẫu đi cùng (nếu là tài xế) hoặc ngược lại
  status: StaffStatus

  // Thống kê hiệu suất
  total_trips: number
  incidents_count: number
  on_time_rate: number

  // Giấy tờ & chứng chỉ
  primary_doc_title: string
  primary_doc_expiry: string
  primary_doc_status: DocStatus
  documents: StaffDocument[]
}

export interface StaffFormPayload {
  full_name: string
  phone: string
  email: string
  role: StaffRole
  code: string
  license_number?: string
  license_expiry?: string
  department?: string
}