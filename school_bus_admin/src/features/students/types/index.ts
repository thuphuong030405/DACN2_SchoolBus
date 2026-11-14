export type FaceStatus = 'REGISTERED' | 'NEEDS_UPDATE' | 'NONE'

export interface StudentRow {
  id: string
  code: string
  fullName: string
  className: string
  avatarUrl: string | null
  parentName: string
  parentPhone: string // đã che bớt, ví dụ 09•• ••• 678
  hasParent: boolean // có phụ huynh đã được duyệt
  routeCode: string
  pickupStop: string
  faceStatus: FaceStatus
  faceCount: number
}

export interface ChildRequest {
  studentId: string
  parentId: string
  studentCode: string
  fullName: string
  dateOfBirth: string | null // YYYY-MM-DD
  gender: string | null
  className: string
  relationship: string
  parentName: string
  parentPhone: string
  parentEmail: string
}