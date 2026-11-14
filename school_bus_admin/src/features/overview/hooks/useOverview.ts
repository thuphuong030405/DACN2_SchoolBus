import { useCallback, useEffect, useState } from 'react'
import { getOverviewData, updateAbsenceStatus } from '../services/overviewService'
import type { OverviewData } from '../types/types'

const initialData: OverviewData = {
  stats: { buses: 0, students: 0, staff: 0, alerts: 0, onboard: 0 },
  alerts: [],
  absences: [],
  attendanceChart: [],
  aiPercent: 0,
  locations: [],
}

export function useOverview() {
  const [data, setData] = useState<OverviewData>(initialData)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [processingId, setProcessingId] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await getOverviewData()
      setData(result)
    } catch (err) {
      console.error('Không thể tải dữ liệu tổng quan:', err)
      setError(err instanceof Error ? err.message : 'Không thể tải dữ liệu dashboard.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [refresh])

  const reviewAbsence = useCallback(
    async (absenceId: string, status: 'APPROVED' | 'REJECTED') => {
      const action = status === 'APPROVED' ? 'duyệt' : 'từ chối'
      if (!window.confirm(`Bạn có chắc chắn muốn ${action} đơn xin nghỉ này?`)) return

      setProcessingId(absenceId)
      try {
        await updateAbsenceStatus(absenceId, status)
        await refresh()
        window.alert(status === 'APPROVED' ? 'Đã duyệt đơn xin nghỉ.' : 'Đã từ chối đơn xin nghỉ.')
      } catch (err) {
        window.alert(err instanceof Error ? err.message : 'Không thể cập nhật đơn xin nghỉ.')
      } finally {
        setProcessingId(null)
      }
    },
    [refresh],
  )

  return {
    ...data,
    loading,
    error,
    processingId,
    refresh,
    reviewAbsence,
  }
}
