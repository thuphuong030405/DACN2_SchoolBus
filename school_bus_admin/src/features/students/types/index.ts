export type FaceStatus = 'REGISTERED' | 'NEEDS_UPDATE' | 'NONE'

export interface StudentRow {
  id: string
  code: string
  fullName: string
  className: string
  avatarUrl: string | null
  parentName: string
  parentPhone: string // đã che bớt, ví dụ 09•• ••• 678
  routeCode: string
  pickupStop: string
  faceStatus: FaceStatus
  faceCount: number // số vector hợp lệ (đủ 3 góc là đạt)
}