import { useCallback, useEffect, useMemo, useState } from 'react'

import {
  calculateAbsenceStats,
  getAbsences,
  updateAbsenceStatus,
} from '../services/absenceService'

import type {
  AbsenceRequest,
  AbsenceStats,
  AbsenceStatus,
  AbsenceTab,
} from '../types'

export function useAbsences() {
  const [requests, setRequests] = useState<AbsenceRequest[]>([])
  const [selectedRequest, setSelectedRequest] =
    useState<AbsenceRequest | null>(null)

  const [activeTab, setActiveTab] = useState<AbsenceTab>('PENDING')
  const [search, setSearch] = useState('')
  const [adminNote, setAdminNote] = useState('')

  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadAbsences = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const data = await getAbsences()

      setRequests(data)

      setSelectedRequest((current) => {
        if (current) {
          const updated = data.find((item) => item.id === current.id)
          if (updated) return updated
        }

        return (
          data.find((item) => item.status === 'PENDING') ||
          data[0] ||
          null
        )
      })
    } catch (err) {
      const message =
        err instanceof Error
          ? err.message
          : 'Không thể tải danh sách đơn xin nghỉ.'

      setError(message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadAbsences()
  }, [loadAbsences])

  const stats: AbsenceStats = useMemo(
    () => calculateAbsenceStats(requests),
    [requests],
  )

  const tabCounts = useMemo(
    () => ({
      ALL: requests.length,
      PENDING: stats.pending,
      APPROVED: stats.approved,
      REJECTED: stats.rejected,
    }),
    [requests.length, stats],
  )

  const filteredRequests = useMemo(() => {
    const keyword = search.trim().toLowerCase()

    return requests.filter((item) => {
      const matchesTab =
        activeTab === 'ALL' || item.status === activeTab

      const matchesSearch =
        !keyword ||
        item.studentName.toLowerCase().includes(keyword) ||
        item.studentClass.toLowerCase().includes(keyword) ||
        item.parentName.toLowerCase().includes(keyword)

      return matchesTab && matchesSearch
    })
  }, [requests, activeTab, search])

  const selectRequest = useCallback((request: AbsenceRequest) => {
    setSelectedRequest(request)
    setAdminNote('')
  }, [])

  const changeTab = useCallback((tab: AbsenceTab) => {
    setActiveTab(tab)
  }, [])

  const updateStatus = useCallback(
    async (status: Extract<AbsenceStatus, 'APPROVED' | 'REJECTED'>) => {
      if (!selectedRequest) return false

      if (
        status === 'REJECTED' &&
        !adminNote.trim()
      ) {
        setError('Vui lòng nhập lý do từ chối đơn.')
        return false
      }

      setProcessing(true)
      setError(null)

      try {
        await updateAbsenceStatus(
          selectedRequest.id,
          status,
          adminNote,
        )

        await loadAbsences()
        setAdminNote('')

        return true
      } catch (err) {
        const message =
          err instanceof Error
            ? err.message
            : 'Không thể cập nhật trạng thái đơn.'

        setError(message)
        return false
      } finally {
        setProcessing(false)
      }
    },
    [selectedRequest, adminNote, loadAbsences],
  )

  return {
    requests,
    filteredRequests,
    selectedRequest,
    activeTab,
    search,
    adminNote,
    loading,
    processing,
    error,
    stats,
    tabCounts,

    setSearch,
    setAdminNote,
    setError,
    changeTab,
    selectRequest,
    loadAbsences,

    approve: () => updateStatus('APPROVED'),
    reject: () => updateStatus('REJECTED'),
  }
}