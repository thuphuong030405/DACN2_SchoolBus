import { useEffect, useMemo, useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { RefreshCw } from 'lucide-react'
import { useAttendance } from './hooks/useAttendance'
import { AttendanceStats } from './components/AttendanceStats'
import { AttendanceTable, type FilterTab } from './components/AttendanceTable'
import { AttendanceSidebar } from './components/AttendanceSidebar'
import type { StudentAttendanceRow, TripOption } from './types'

function formatVietnameseDate(dateStr?: string): string {
  const date = dateStr ? new Date(`${dateStr}T00:00:00+07:00`) : new Date()
  const formatted = new Intl.DateTimeFormat('vi-VN', {
    weekday: 'long',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'Asia/Ho_Chi_Minh',
  }).format(date)
  return formatted.charAt(0).toUpperCase() + formatted.slice(1)
}

export function AttendancePage() {
  const queryClient = useQueryClient()
  const [selectedTripId, setSelectedTripId] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<FilterTab>('ALL')
  const [trips, setTrips] = useState<TripOption[]>([])

  const selectedTrip = useMemo(
    () => trips.find((t) => t.trip_id === selectedTripId) ?? trips[0] ?? null,
    [trips, selectedTripId]
  )

  const {
    tripsQuery,
    tripAttendanceQuery,
    overviewQuery,
    manualCheckInMutation,
    completeTripMutation,
  } = useAttendance(selectedTrip)

  useEffect(() => {
    if (tripsQuery.data) {
      setTrips(tripsQuery.data)
      if (!selectedTripId && tripsQuery.data.length > 0) {
        const running = tripsQuery.data.find((t) => t.status === 'IN_PROGRESS')
        setSelectedTripId((running ?? tripsQuery.data[0]).trip_id)
      }
    }
  }, [tripsQuery.data, selectedTripId])

  const rows = tripAttendanceQuery.data ?? []

  const tripStats = useMemo(() => {
    const total = rows.length
    const boardedCount = rows.filter(
      (r) => r.status === 'BOARDED' || r.status === 'ALIGHTED'
    ).length
    const alightedCount = rows.filter((r) => r.status === 'ALIGHTED').length
    const onBusCount = Math.max(0, boardedCount - alightedCount)
    const pendingCount = rows.filter((r) => r.status === 'PENDING').length
    const absentCount = rows.filter((r) => r.status === 'ABSENT').length
    const progressPercent =
      total > 0 ? Math.round((boardedCount / total) * 100) : 0

    return {
      total,
      boardedCount,
      alightedCount,
      onBusCount,
      pendingCount,
      absentCount,
      progressPercent,
    }
  }, [rows])

  const filteredRows = useMemo(() => {
    return rows.filter((r) => {
      if (activeTab === 'ALL') return true
      if (activeTab === 'BOARDED') {
        return r.status === 'BOARDED' || r.status === 'ALIGHTED'
      }
      return r.status === activeTab
    })
  }, [rows, activeTab])

  const summary = overviewQuery.data?.summary ?? {
    expected_today: 0,
    boarded_today: 0,
    ai_rate: 0,
    pending_today: 0,
    absent_today: 0,
  }

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: ['attendance-trips'] })
    queryClient.invalidateQueries({ queryKey: ['trip-attendance'] })
    queryClient.invalidateQueries({ queryKey: ['attendance-overview'] })
  }

  const handleManualCheckIn = async (row: StudentAttendanceRow) => {
    if (!selectedTrip) return
    try {
      await manualCheckInMutation.mutateAsync({
        tripId: selectedTrip.trip_id,
        studentId: row.student_id,
        pickupStopId: row.pickup_stop_id,
      })
    } catch (err: any) {
      alert(`Lỗi điểm danh tay: ${err?.message || 'Không thể lưu điểm danh'}`)
    }
  }

  const handleCompleteTrip = async () => {
    if (!selectedTrip) return
    if (tripStats.onBusCount > 0) {
      alert(
        `CẢNH BÁO AN TOÀN: Vẫn còn ${tripStats.onBusCount} học sinh trên xe! Chỉ được chốt chuyến khi số lượt lên bằng số lượt xuống.`
      )
      return
    }
    try {
      await completeTripMutation.mutateAsync(selectedTrip.trip_id)
      alert('Đã chốt chuyến an toàn!')
    } catch (err: any) {
      alert(`Lỗi chốt chuyến: ${err?.message || 'Không thể cập nhật trạng thái'}`)
    }
  }

  return (
    <div className="flex min-h-[calc(100vh-80px)] flex-col gap-5">
      {/* HEADER */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Điểm danh
          </h1>
          <p className="mt-0.5 text-xs text-slate-500">
            {formatVietnameseDate(selectedTrip?.trip_date)} · Cập nhật trực
            tiếp từ xe
          </p>
        </div>

        <button
          type="button"
          onClick={handleRefresh}
          title="Làm mới dữ liệu điểm danh"
          className="grid size-10 place-items-center rounded-xl border border-slate-200 bg-white text-slate-600 shadow-2xs transition hover:bg-slate-50"
        >
          <RefreshCw
            className={`size-4 ${
              tripAttendanceQuery.isFetching ? 'animate-spin text-blue-600' : ''
            }`}
          />
        </button>
      </div>

      {/* 4 THẺ KPI */}
      <AttendanceStats summary={summary} />

      {/* NỘI DUNG 2 CỘT */}
      <div className="grid flex-1 grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_340px]">
        <AttendanceTable
          trips={trips}
          selectedTrip={selectedTrip}
          onSelectTrip={setSelectedTripId}
          rows={filteredRows}
          isLoading={tripAttendanceQuery.isLoading}
          activeTab={activeTab}
          onTabChange={setActiveTab}
          stats={tripStats}
          isCheckingIn={manualCheckInMutation.isPending}
          onManualCheckIn={handleManualCheckIn}
        />

        <AttendanceSidebar
          selectedTrip={selectedTrip}
          boardedCount={tripStats.boardedCount}
          alightedCount={tripStats.alightedCount}
          onBusCount={tripStats.onBusCount}
          routeProgress={overviewQuery.data?.routeProgress ?? []}
          isCompleting={completeTripMutation.isPending}
          onCompleteTrip={handleCompleteTrip}
        />
      </div>
    </div>
  )
}

export default AttendancePage