
import { useMemo } from 'react'
import {
  Search,
  Check,
  X,
  AlertCircle,
  Calendar,
  Users,
  Download,
  RefreshCw,
} from 'lucide-react'

import { useAbsences } from './hooks/useAbsences'
import type { AbsenceTab } from './types'

import './AbsencesPage.css'

const tabs: AbsenceTab[] = [
  'PENDING',
  'APPROVED',
  'REJECTED',
  'ALL',
]

const tabLabels: Record<AbsenceTab, string> = {
  PENDING: 'Chờ duyệt',
  APPROVED: 'Đã duyệt',
  REJECTED: 'Từ chối',
  ALL: 'Tất cả',
}

function formatDate(date: string) {
  if (!date) return '--'

  return new Date(`${date.slice(0, 10)}T00:00:00`)
    .toLocaleDateString('vi-VN')
}

function formatSession(session: string) {
  if (session === 'MORNING') return 'Đón sáng'
  if (session === 'AFTERNOON') return 'Trả chiều'
  return session
}

function formatStatus(status: string) {
  if (status === 'PENDING') return 'Chờ duyệt'
  if (status === 'APPROVED') return 'Đã duyệt'
  if (status === 'REJECTED') return 'Từ chối'
  return status
}

function exportCSV(requests: ReturnType<typeof useAbsences>['requests']) {
  const headers = [
    'Học sinh',
    'Lớp',
    'Phụ huynh',
    'Ngày nghỉ',
    'Buổi',
    'Lý do',
    'Trạng thái',
    'Tuyến xe',
  ]

  const rows = requests.map((item) => [
    item.studentName,
    item.studentClass,
    item.parentName,
    item.date,
    formatSession(item.session),
    item.reason,
    formatStatus(item.status),
    item.routeInfo,
  ])

  const csv = [headers, ...rows]
    .map((row) =>
      row.map((value) =>
        `"${String(value ?? '').replace(/"/g, '""')}"`
      ).join(',')
    )
    .join('\n')

  const blob = new Blob(['\uFEFF' + csv], {
    type: 'text/csv;charset=utf-8;',
  })

  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')

  link.href = url
  link.download = 'danh-sach-don-xin-nghi.csv'
  link.click()

  URL.revokeObjectURL(url)
}

export function AbsencesPage() {
  const {
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
    changeTab,
    selectRequest,
    loadAbsences,
    approve,
    reject,
  } = useAbsences()

  const approvedThisWeek = useMemo(() => {
    const now = new Date()
    const monday = new Date(now)
    const offset = now.getDay() === 0 ? 6 : now.getDay() - 1

    monday.setDate(now.getDate() - offset)
    monday.setHours(0, 0, 0, 0)

    const nextMonday = new Date(monday)
    nextMonday.setDate(monday.getDate() + 7)

    return requests.filter((item) => {
      if (item.status !== 'APPROVED' || !item.reviewedAt) {
        return false
      }

      const reviewedAt = new Date(item.reviewedAt)

      return reviewedAt >= monday && reviewedAt < nextMonday
    }).length
  }, [requests])

  const handleApprove = async () => {
    await approve()
  }

  const handleReject = async () => {
    await reject()
  }

  return (
    <div className="leave-page">
      <header className="leave-header">
        <div>
          <h1>Đơn xin nghỉ</h1>
          <p>Duyệt đơn của phụ huynh và cập nhật lộ trình tự động</p>
        </div>

        <button
          type="button"
          className="leave-export-btn"
          onClick={() => exportCSV(filteredRequests)}
        >
          <Download size={15} />
          Xuất danh sách
        </button>
      </header>

      {error && (
        <div className="leave-error">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      <section className="leave-stats-grid">
        <div className="leave-stat-card">
          <div className="leave-stat-icon yellow">
            <Calendar size={20} />
          </div>
          <div>
            <span>Chờ duyệt</span>
            <strong>{stats.pending}</strong>
            <small>Các đơn đang chờ xử lý</small>
          </div>
        </div>

        <div className="leave-stat-card">
          <div className="leave-stat-icon green">
            <Check size={20} />
          </div>
          <div>
            <span>Đã duyệt tuần này</span>
            <strong>{approvedThisWeek}</strong>
            <small>Đơn đã được xử lý trong tuần</small>
          </div>
        </div>

        <div className="leave-stat-card">
          <div className="leave-stat-icon blue">
            <Users size={20} />
          </div>
          <div>
            <span>Học sinh nghỉ hôm nay</span>
            <strong>{stats.absentToday}</strong>
            <small>Theo đơn đã duyệt</small>
          </div>
        </div>
      </section>

      <div className="leave-content-grid">
        <section className="leave-panel">
          <div className="leave-panel-heading">
            <h2>Danh sách đơn xin nghỉ</h2>

            <button
              type="button"
              className="leave-export-btn"
              onClick={() => void loadAbsences()}
              disabled={loading}
            >
              <RefreshCw size={15} />
              Làm mới
            </button>
          </div>

          <div className="leave-toolbar">
            <div className="leave-tabs">
              {tabs.map((tab) => (
                <button
                  key={tab}
                  type="button"
                  className={activeTab === tab ? 'active' : ''}
                  onClick={() => changeTab(tab)}
                >
                  {tabLabels[tab]} {tabCounts[tab]}
                </button>
              ))}
            </div>

            <div className="leave-search">
              <Search size={16} />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm học sinh, phụ huynh, lớp..."
              />
            </div>
          </div>

          <div className="leave-table-wrap">
            {loading ? (
              <div className="leave-empty">
                <RefreshCw size={25} />
                <p>Đang tải dữ liệu từ cơ sở dữ liệu...</p>
              </div>
            ) : filteredRequests.length === 0 ? (
              <div className="leave-empty">
                <AlertCircle size={25} />
                <p>Không có đơn xin nghỉ nào.</p>
              </div>
            ) : (
              <table className="leave-table">
                <thead>
                  <tr>
                    <th>Học sinh</th>
                    <th>Phụ huynh</th>
                    <th>Ngày nghỉ</th>
                    <th>Buổi</th>
                    <th>Lý do</th>
                    <th>Trạng thái</th>
                    <th style={{ textAlign: 'right' }}>Thao tác</th>
                  </tr>
                </thead>

                <tbody>
                  {filteredRequests.map((item) => (
                    <tr
                      key={item.id}
                      className={
                        selectedRequest?.id === item.id
                          ? 'selected-row'
                          : ''
                      }
                      onClick={() => selectRequest(item)}
                    >
                      <td>
                        <strong>{item.studentName}</strong>
                        <small>{item.studentClass}</small>
                      </td>

                      <td>{item.parentName}</td>
                      <td>{formatDate(item.date)}</td>
                      <td>{formatSession(item.session)}</td>
                      <td>{item.reason}</td>

                      <td>
                        <span
                          className={`leave-status-badge ${item.status.toLowerCase()}`}
                        >
                          {formatStatus(item.status)}
                        </span>
                      </td>

                      <td style={{ textAlign: 'right' }}>
                        {item.status === 'PENDING' && (
                          <div
                            className="leave-row-actions"
                            onClick={(e) => e.stopPropagation()}
                          >
                            <button
                              type="button"
                              className="action-icon-btn approve"
                              title="Duyệt"
                              disabled={processing}
                              onClick={() => {
                                selectRequest(item)
                                // Chọn đơn rồi xử lý tại phần chi tiết
                              }}
                            >
                              <Check size={14} />
                            </button>

                            <button
                              type="button"
                              className="action-icon-btn reject"
                              title="Từ chối"
                              onClick={() => selectRequest(item)}
                            >
                              <X size={14} />
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="leave-table-footer-note">
            Đơn được duyệt sẽ được cập nhật trạng thái trong hệ thống.
          </div>
        </section>

        <div className="leave-right-column">
          <section className="leave-panel leave-detail-card">
            {!selectedRequest ? (
              <div className="leave-empty">
                <p>Chọn một đơn để xem chi tiết</p>
              </div>
            ) : (
              <>
                <div className="leave-detail-header">
                  <div>
                    <h2>
                      {selectedRequest.studentName} ·{' '}
                      {selectedRequest.studentClass}
                    </h2>
                    <small>
                      Phụ huynh: {selectedRequest.parentName}
                    </small>
                  </div>

                  <span
                    className={`leave-status-badge ${selectedRequest.status.toLowerCase()}`}
                  >
                    {formatStatus(selectedRequest.status)}
                  </span>
                </div>

                <div className="leave-detail-info-grid">
                  <div className="info-row">
                    <span>Thời gian nghỉ</span>
                    <strong>
                      {formatDate(selectedRequest.date)} ·{' '}
                      {formatSession(selectedRequest.session)}
                    </strong>
                  </div>

                  <div className="info-row">
                    <span>Lý do</span>
                    <strong>{selectedRequest.reason}</strong>
                  </div>

                  <div className="info-row">
                    <span>Gửi lúc</span>
                    <span>
                      {new Date(selectedRequest.submittedAt).toLocaleString('vi-VN')}
                    </span>
                  </div>

                  <div className="info-row">
                    <span>Tuyến xe</span>
                    <strong>{selectedRequest.routeInfo}</strong>
                  </div>
                </div>

                {selectedRequest.rejectionNote && (
                  <div className="leave-route-impact-box">
                    <AlertCircle size={18} color="#dc2626" />
                    <p>
                      Lý do từ chối: {selectedRequest.rejectionNote}
                    </p>
                  </div>
                )}

                {selectedRequest.status === 'PENDING' && (
                  <>
                    <div className="leave-note-box">
                      <label>Ghi chú / Lý do từ chối</label>
                      <input
                        type="text"
                        value={adminNote}
                        onChange={(e) => setAdminNote(e.target.value)}
                        placeholder="Nhập lý do nếu từ chối..."
                      />
                    </div>

                    <div className="leave-action-buttons">
                      <button
                        type="button"
                        className="btn-approve-lg"
                        disabled={processing}
                        onClick={() => void handleApprove()}
                      >
                        <Check size={16} />
                        {processing ? 'Đang xử lý...' : 'Duyệt đơn'}
                      </button>

                      <button
                        type="button"
                        className="btn-reject-lg"
                        disabled={processing || !adminNote.trim()}
                        onClick={() => void handleReject()}
                      >
                        <X size={16} />
                        Từ chối
                      </button>
                    </div>
                  </>
                )}
              </>
            )}
          </section>
        </div>
      </div>
    </div>
  )
}

export default AbsencesPage
