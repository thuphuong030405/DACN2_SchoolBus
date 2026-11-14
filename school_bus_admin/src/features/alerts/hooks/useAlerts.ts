
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react'

import {
  calculateAlertStats,
  getAlerts,
  updateAlertStatus,
} from '../services/alertService'

import type {
  AlertItem,
  AlertTab,
} from '../types'

export function useAlerts() {
  const [alerts, setAlerts] = useState<AlertItem[]>([])
  const [selectedAlert, setSelectedAlert] =
    useState<AlertItem | null>(null)

  const [selectedTab, setSelectedTab] =
    useState<AlertTab>('ALL')

  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // ========================================
  // LOAD DATA
  // ========================================

  const loadAlerts = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      const data = await getAlerts()

      setAlerts(data)

      setSelectedAlert((current) => {
        if (!current) {
          return data[0] ?? null
        }

        return (
          data.find((item) => item.id === current.id) ??
          data[0] ??
          null
        )
      })
    } catch (err) {
      console.error('loadAlerts:', err)

      setError(
        err instanceof Error
          ? err.message
          : 'Không thể tải danh sách cảnh báo.',
      )
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadAlerts()
  }, [loadAlerts])

  // ========================================
  // STATISTICS
  // ========================================

  const stats = useMemo(
    () => calculateAlertStats(alerts),
    [alerts],
  )

  // ========================================
  // TAB COUNTS
  // ========================================

  const tabCounts = useMemo(() => {
    const pending = alerts.filter(
      (item) =>
        item.status === 'OPEN' ||
        item.status === 'PROCESSING',
    ).length

    const resolved = alerts.filter(
      (item) =>
        item.status === 'RESOLVED' ||
        item.status === 'CLOSED',
    ).length

    return {
      ALL: alerts.length,
      PENDING: pending,
      RESOLVED: resolved,
    }
  }, [alerts])

  // ========================================
  // FILTER AND SEARCH
  // ========================================

  const filteredAlerts = useMemo(() => {
    const keyword = search.trim().toLowerCase()

    return alerts.filter((item) => {
      const isPending =
        item.status === 'OPEN' ||
        item.status === 'PROCESSING'

      const isResolved =
        item.status === 'RESOLVED' ||
        item.status === 'CLOSED'

      const matchesTab =
        selectedTab === 'ALL' ||
        (selectedTab === 'PENDING' && isPending) ||
        (selectedTab === 'RESOLVED' && isResolved)

      const matchesSearch =
        !keyword ||
        item.title.toLowerCase().includes(keyword) ||
        item.busPlate.toLowerCase().includes(keyword) ||
        item.routeName.toLowerCase().includes(keyword) ||
        item.category.toLowerCase().includes(keyword) ||
        item.description.toLowerCase().includes(keyword)

      return matchesTab && matchesSearch
    })
  }, [alerts, selectedTab, search])

  // ========================================
  // SELECT ALERT
  // ========================================

  const selectAlert = useCallback((alert: AlertItem) => {
    setSelectedAlert(alert)
    setError(null)
  }, [])

  // ========================================
  // CHANGE TAB
  // ========================================

  const changeTab = useCallback((tab: AlertTab) => {
    setSelectedTab(tab)
  }, [])

  // ========================================
  // RESOLVE ALERT
  // ========================================

  const resolveAlert = useCallback(
    async (alertId?: string) => {
      const targetId = alertId ?? selectedAlert?.id

      if (!targetId) {
        setError('Vui lòng chọn cảnh báo cần xử lý.')
        return
      }

      const target = alerts.find(
        (item) => item.id === targetId,
      )

      if (!target) {
        setError('Không tìm thấy cảnh báo.')
        return
      }

      if (
        target.status === 'RESOLVED' ||
        target.status === 'CLOSED'
      ) {
        setError('Cảnh báo này đã được xử lý.')
        return
      }

      try {
        setProcessing(true)
        setError(null)

        await updateAlertStatus(targetId)

        // Cập nhật danh sách sau khi Supabase thành công
        setAlerts((previous) =>
          previous.map((item) =>
            item.id === targetId
              ? {
                  ...item,
                  status: 'RESOLVED',
                }
              : item,
          ),
        )

        // Cập nhật phần chi tiết
        setSelectedAlert((previous) =>
          previous?.id === targetId
            ? {
                ...previous,
                status: 'RESOLVED',
              }
            : previous,
        )
      } catch (err) {
        console.error('resolveAlert:', err)

        setError(
          err instanceof Error
            ? err.message
            : 'Không thể cập nhật trạng thái cảnh báo.',
        )
      } finally {
        setProcessing(false)
      }
    },
    [alerts, selectedAlert],
  )

  return {
    alerts,
    filteredAlerts,
    selectedAlert,

    selectedTab,
    search,

    loading,
    processing,
    error,

    stats,
    tabCounts,

    setSearch,
    setError,

    selectAlert,
    changeTab,
    loadAlerts,
    resolveAlert,
  }
}
