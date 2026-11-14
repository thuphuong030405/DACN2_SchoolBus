import type {
  AbsenceRequest,
  AbsenceTab,
} from '../types'

import './AbsenceTable.css'

interface AbsenceTableProps {
  requests: AbsenceRequest[]
  selectedRequestId: string | null
  activeTab: AbsenceTab
  search: string
  tabCounts: Record<AbsenceTab, number>
  loading: boolean
  onTabChange: (tab: AbsenceTab) => void
  onSearchChange: (value: string) => void
  onSelect: (request: AbsenceRequest) => void
  onExport: () => void
}

const tabs: { label: string; value: AbsenceTab }[] = [
  { label: 'Tất cả', value: 'ALL' },
  { label: 'Chờ duyệt', value: 'PENDING' },
  { label: 'Đã duyệt', value: 'APPROVED' },
  { label: 'Từ chối', value: 'REJECTED' },
]

function formatDate(date: string) {
  if (!date) return '--'

  const parsed = new Date(`${date.slice(0, 10)}T00:00:00`)

  return Number.isNaN(parsed.getTime())
    ? date
    : parsed.toLocaleDateString('vi-VN')
}

function getStatusLabel(status: AbsenceRequest['status']) {
  switch (status) {
    case 'PENDING':
      return 'Chờ duyệt'
    case 'APPROVED':
      return 'Đã duyệt'
    case 'REJECTED':
      return 'Từ chối'
  }
}

export default function AbsenceTable({
  requests,
  selectedRequestId,
  activeTab,
  search,
  tabCounts,
  loading,
  onTabChange,
  onSearchChange,
  onSelect,
  onExport,
}: AbsenceTableProps) {
  return (
    <section className="leave-list-panel">
      <div className="leave-panel-header">
        <div>
          <h2 className="leave-panel-title">Danh sách đơn xin nghỉ</h2>
          <p className="leave-panel-subtitle">
            Quản lý và xử lý đơn xin nghỉ của học sinh
          </p>
        </div>

        <button
          type="button"
          className="leave-export-btn"
          onClick={onExport}
        >
          <span>↓</span> Xuất Excel
        </button>
      </div>

      <div className="leave-toolbar">
        <div className="leave-tabs">
          {tabs.map((tab) => (
            <button
              type="button"
              key={tab.value}
              className={`leave-tab ${
                activeTab === tab.value ? 'active' : ''
              }`}
              onClick={() => onTabChange(tab.value)}
            >
              {tab.label}
              <span className="leave-tab-count">
                {tabCounts[tab.value]}
              </span>
            </button>
          ))}
        </div>

        <div className="leave-search">
          <span className="leave-search-icon">⌕</span>
          <input
            type="text"
            placeholder="Tìm học sinh, phụ huynh, lớp..."
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
          />
          {search && (
            <button
              type="button"
              className="leave-clear-search"
              onClick={() => onSearchChange('')}
              aria-label="Xóa tìm kiếm"
            >
              ×
            </button>
          )}
        </div>
      </div>

      <div className="leave-table-wrapper">
        <table className="leave-table">
          <thead>
            <tr>
              <th>HỌC SINH</th>
              <th>PHỤ HUYNH</th>
              <th>NGÀY NGHỈ</th>
              <th>BUỔI</th>
              <th>TRẠNG THÁI</th>
              <th></th>
            </tr>
          </thead>

          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} className="leave-empty">
                  Đang tải dữ liệu...
                </td>
              </tr>
            ) : requests.length === 0 ? (
              <tr>
                <td colSpan={6} className="leave-empty">
                  Không tìm thấy đơn xin nghỉ nào.
                </td>
              </tr>
            ) : (
              requests.map((request) => (
                <tr
                  key={request.id}
                  className={
                    selectedRequestId === request.id ? 'selected' : ''
                  }
                  onClick={() => onSelect(request)}
                >
                  <td>
                    <div className="leave-student-cell">
                      <div className="leave-avatar">
                        {request.studentName.charAt(0).toUpperCase()}
                      </div>

                      <div>
                        <div className="leave-student-name">
                          {request.studentName}
                        </div>
                        <div className="leave-student-class">
                          {request.studentClass}
                        </div>
                      </div>
                    </div>
                  </td>

                  <td>{request.parentName}</td>

                  <td>{formatDate(request.date)}</td>

                  <td>
                    {request.session === 'MORNING'
                      ? 'Buổi sáng'
                      : 'Buổi chiều'}
                  </td>

                  <td>
                    <span
                      className={`leave-status leave-status-${request.status.toLowerCase()}`}
                    >
                      <span className="leave-status-dot" />
                      {getStatusLabel(request.status)}
                    </span>
                  </td>

                  <td>
                    <button
                      type="button"
                      className="leave-view-btn"
                      onClick={(event) => {
                        event.stopPropagation()
                        onSelect(request)
                      }}
                    >
                      Chi tiết
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="leave-table-footer">
        Hiển thị <strong>{requests.length}</strong> đơn xin nghỉ
      </div>
    </section>
  )
}