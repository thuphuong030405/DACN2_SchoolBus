
export type AbsenceStatus =
  | 'PENDING'
  | 'APPROVED'
  | 'REJECTED'

export type AbsenceSession =
  | 'MORNING'
  | 'AFTERNOON'

export type AbsenceTab =
  | 'ALL'
  | AbsenceStatus

export interface AbsenceRequest {
  id: string
  studentId: string
  parentId: string

  studentName: string
  studentClass: string
  parentName: string

  date: string
  session: AbsenceSession
  reason: string

  status: AbsenceStatus
  submittedAt: string
  rejectionNote: string | null

  routeInfo: string
  reviewedAt: string | null
}

export interface AbsenceStats {
  pending: number
  approved: number
  rejected: number
  absentToday: number
}
