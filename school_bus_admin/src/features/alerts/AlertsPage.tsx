
import {
  AlertTriangle,
  Bell,
  CheckCircle2,
  MapPin,
  RefreshCw,
  Search,
  ShieldAlert,
} from 'lucide-react'

import { useAlerts } from './hooks/useAlerts'
import type { AlertTab } from './types'

import './AlertsPage.css'

const tabs: AlertTab[] = [
  'ALL',
  'PENDING',
  'RESOLVED',
]

const tabLabels: Record<AlertTab, string> = {
  ALL: 'Tất cả',
  PENDING: 'Chưa xử lý',
  RESOLVED: 'Đã xử lý',
}

function getStatusLabel(status: string) {
  switch (status) {
    case 'OPEN':
      return 'Mới phát sinh'
    case 'PROCESSING':
      return 'Đang xử lý'
    case 'RESOLVED':
      return 'Đã giải quyết'
    case 'CLOSED':
      return 'Đã đóng'
    default:
      return status
  }
}

export function AlertsPage() {
  const {
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
  } = useAlerts()

  const isPending =
    selectedAlert?.status === 'OPEN' ||
    selectedAlert?.status === 'PROCESSING'

  return (
    <div className="alerts-page">
      {/* HEADER */}
      <header className="alerts-header">
        <div>
          <h1>Cảnh báo hệ thống</h1>
          <p>
            Giám sát và xử lý các sự cố phát sinh trên đội xe
            theo thời gian thực
          </p>
        </div>
      </header>

      {/* ERROR */}
      {error && (
        <div className="alerts-error">
          <span>{error}</span>
          <button
            type="button"
            onClick={() => setError(null)}
          >
            Đóng
          </button>
        </div>
      )}

      {/* STATS */}
      <section className="alerts-stats-grid">
        <div className="alerts-stat-card">
          <div className="alerts-stat-icon red">
            <ShieldAlert size={20} />
          </div>
          <div>
            <span>Cảnh báo nguy hiểm</span>
            <strong>{loading ? '...' : stats.danger}</strong>
            <small>Cần xử lý ngay lập tức</small>
          </div>
        </div>

        <div className="alerts-stat-card">
          <div className="alerts-stat-icon yellow">
            <AlertTriangle size={20} />
          </div>
          <div>
            <span>Cảnh báo chú ý</span>
            <strong>{loading ? '...' : stats.warning}</strong>
            <small>Theo dõi tiến trình</small>
          </div>
        </div>

        <div className="alerts-stat-card">
          <div className="alerts-stat-icon blue">
            <Bell size={20} />
          </div>
          <div>
            <span>Tổng chờ xử lý</span>
            <strong>{loading ? '...' : stats.pending}</strong>
            <small>Sự cố chưa giải quyết</small>
          </div>
        </div>
      </section>

      {/* MAIN CONTENT */}
      <div className="alerts-content-grid">
        {/* LEFT: ALERT LIST */}
        <section className="alerts-panel">
          <div className="alerts-panel-heading alerts-heading-row">
            <h2>
              Danh sách cảnh báo ({filteredAlerts.length})
            </h2>

            <button
              type="button"
              className="alerts-refresh-btn"
              onClick={() => void loadAlerts()}
              disabled={loading}
            >
              <RefreshCw
                size={15}
                className={loading ? 'spin' : ''}
              />
              Làm mới
            </button>
          </div>

          {/* TOOLBAR */}
          <div className="alerts-toolbar">
            <div className="alerts-tabs">
              {tabs.map((tab) => (
                <button
                  key={tab}
                  type="button"
                  className={
                    selectedTab === tab ? 'active' : ''
                  }
                  onClick={() => changeTab(tab)}
                >
                  {tabLabels[tab]} ({tabCounts[tab]})
                </button>
              ))}
            </div>

            <div className="alerts-search">
              <Search size={16} />
              <input
                value={search}
                onChange={(event) =>
                  setSearch(event.target.value)
                }
                placeholder="Tìm biển số, tuyến, nội dung..."
              />
            </div>
          </div>

          {/* TABLE */}
          <div className="alerts-table-wrap">
            <table className="alerts-table">
              <thead>
                <tr>
                  <th>Mức độ</th>
                  <th>Nội dung cảnh báo</th>
                  <th>Phương tiện</th>
                  <th>Tuyến đường</th>
                  <th>Thời gian</th>
                  <th>Trạng thái</th>
                </tr>
              </thead>

              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={6} className="alerts-empty">
                      Đang tải dữ liệu từ hệ thống...
                    </td>
                  </tr>
                ) : filteredAlerts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="alerts-empty">
                      Không tìm thấy cảnh báo phù hợp.
                    </td>
                  </tr>
                ) : (
                  filteredAlerts.map((item) => (
                    <tr
                      key={item.id}
                      className={
                        selectedAlert?.id === item.id
                          ? 'selected-row'
                          : ''
                      }
                      onClick={() => selectAlert(item)}
                    >
                      <td>
                        <span
                          className={`alerts-type-badge ${item.type.toLowerCase()}`}
                        >
                          {item.type === 'DANGER'
                            ? 'Nguy hiểm'
                            : item.type === 'WARNING'
                              ? 'Cảnh báo'
                              : 'Thông tin'}
                        </span>
                      </td>

                      <td>
                        <strong>{item.title}</strong>
                        <small>{item.category}</small>
                      </td>

                      <td>{item.busPlate}</td>

                      <td>{item.routeName}</td>

                      <td>{item.time}</td>

                      <td>
                        <span
                          className={`alerts-status-pill ${
                            item.status === 'OPEN' ||
                            item.status === 'PROCESSING'
                              ? 'pending'
                              : 'resolved'
                          }`}
                        >
                          {getStatusLabel(item.status)}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </section>

        {/* RIGHT: ALERT DETAIL */}
        <div className="alerts-right-column">
          <section className="alerts-panel alerts-detail-card">
            {!selectedAlert ? (
              <div className="alerts-empty">
                <Bell size={30} />
                <p>Chọn một cảnh báo để xem chi tiết.</p>
              </div>
            ) : (
              <>
                <div className="alerts-detail-header">
                  <div>
                    <h2>Chi tiết sự cố</h2>
                    <small>
                      ID sự cố: #{selectedAlert.id}
                    </small>
                  </div>

                  <span
                    className={`alerts-type-badge ${selectedAlert.type.toLowerCase()}`}
                  >
                    {selectedAlert.type === 'DANGER'
                      ? 'Nguy hiểm'
                      : selectedAlert.type === 'WARNING'
                        ? 'Cảnh báo'
                        : 'Thông tin'}
                  </span>
                </div>

                <div className="alerts-detail-info-grid">
                  <div className="info-row">
                    <span>Tiêu đề</span>
                    <strong>{selectedAlert.title}</strong>
                  </div>

                  <div className="info-row">
                    <span>Loại cảnh báo</span>
                    <strong>{selectedAlert.category}</strong>
                  </div>

                  <div className="info-row">
                    <span>Phương tiện</span>
                    <strong>{selectedAlert.busPlate}</strong>
                  </div>

                  <div className="info-row">
                    <span>Tuyến đường</span>
                    <strong>{selectedAlert.routeName}</strong>
                  </div>

                  <div className="info-row">
                    <span>Thời gian ghi nhận</span>
                    <span>{selectedAlert.time}</span>
                  </div>

                  <div className="info-row">
                    <span>Mức độ</span>
                    <strong>{selectedAlert.severity}</strong>
                  </div>

                  <div className="info-row">
                    <span>Trạng thái</span>
                    <strong
                      className={
                        isPending ? 'text-red' : 'text-green'
                      }
                    >
                      {getStatusLabel(selectedAlert.status)}
                    </strong>
                  </div>

                  {selectedAlert.incidentLocation && (
                    <div className="info-row">
                      <span>
                        <MapPin
                          size={13}
                          style={{
                            display: 'inline',
                            marginRight: 4,
                          }}
                        />
                        Vị trí
                      </span>
                      <strong>
                        {selectedAlert.incidentLocation}
                      </strong>
                    </div>
                  )}
                </div>

                <div className="alerts-description-box">
                  <span className="desc-label">
                    Mô tả chi tiết hệ thống:
                  </span>
                  <p>{selectedAlert.description}</p>
                </div>

                {selectedAlert.resolutionNote && (
                  <div className="resolved-notice-box">
                    <CheckCircle2 size={16} />
                    <span>
                      Ghi chú xử lý: {selectedAlert.resolutionNote}
                    </span>
                  </div>
                )}

                {isPending ? (
                  <button
                    type="button"
                    className="btn-resolve-lg"
                    disabled={processing}
                    onClick={() =>
                      void resolveAlert(selectedAlert.id)
                    }
                  >
                    <CheckCircle2 size={16} />
                    {processing
                      ? 'Đang cập nhật...'
                      : 'Đánh dấu đã xử lý'}
                  </button>
                ) : (
                  <div className="resolved-notice-box">
                    <CheckCircle2 size={16} />
                    <span>
                      Sự cố này đã được xử lý và ghi vào nhật
                      ký vận hành.
                    </span>
                  </div>
                )}
              </>
            )}
          </section>
        </div>
      </div>
    </div>
  )
}

export default AlertsPage
