
import { useMemo, useState } from 'react'

import {
  Bus,
  Search,
  RefreshCw,
  Clock3,
  Users,
  AlertCircle,
  MapPinned,
  Plus,
  MoreVertical,
  Zap,
} from 'lucide-react'

import { useRoutes } from './hooks/useRoutes'
import type { BusWithTrip, RouteSummary } from './types'

import { AddTripModal } from './components/AddTripModal'
import { AddBusModal } from './components/AddBusModal'

import './RoutesPage.css'

interface StatusBadgeProps {
  status: string
}

interface VehicleRowProps {
  bus: BusWithTrip
}

interface RouteMapProps {
  route: RouteSummary
}

// ==============================
// TRẠNG THÁI
// ==============================

function statusLabel(status: string) {
  const labels: Record<string, string> = {
    ACTIVE: 'Hoạt động',
    MAINTENANCE: 'Bảo dưỡng',
    INACTIVE: 'Ngừng hoạt động',
    SCHEDULED: 'Chờ khởi hành',
    IN_PROGRESS: 'Đang chạy',
    COMPLETED: 'Hoàn thành',
    CANCELLED: 'Đã hủy',
  }

  return labels[status] ?? status
}

function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span className={`routes-status routes-status-${status.toLowerCase()}`}>
      <span className="routes-status-dot" />
      {statusLabel(status)}
    </span>
  )
}

// ==============================
// DÒNG PHƯƠNG TIỆN
// ==============================

function VehicleRow({ bus }: VehicleRowProps) {
  const teacherName = bus.teacherName?.trim()
  const driverName = bus.driverName?.trim()

  return (
    <tr>
      <td>
        <div className="routes-vehicle-cell">
          <div className="routes-vehicle-icon">
            <Bus size={17} />
          </div>

          <div>
            <strong className="routes-plate">
              {bus.license_plate}
            </strong>

            <small>{bus.bus_code}</small>
          </div>
        </div>
      </td>

      <td>{bus.capacity} chỗ</td>

      <td>
        {driverName && driverName !== 'Chưa phân công'
          ? driverName
          : 'Chưa được phân công'}
      </td>

      <td>
        {teacherName && teacherName !== 'Chưa phân công'
          ? teacherName
          : 'Chưa được phân công'}
      </td>

      <td>
        <span className="routes-route-name">
          {bus.routeName || 'Chưa có tuyến'}
        </span>
      </td>

      <td>
        <StatusBadge
          status={bus.currentTrip?.status ?? bus.status}
        />
      </td>

      <td className="routes-action-cell">
        <button
          type="button"
          className="routes-action-btn"
          aria-label={`Tùy chọn xe ${bus.license_plate}`}
          title={`Tùy chọn xe ${bus.license_plate}`}
        >
          <MoreVertical size={17} />
        </button>
      </td>
    </tr>
  )
}

// ==============================
// BẢN ĐỒ TUYẾN ĐƯỜNG
// ==============================

function RouteMap({ route }: RouteMapProps) {
  const stops = [...(route?.stops ?? [])]
    .filter(
      (stop) =>
        stop.latitude != null &&
        stop.longitude != null,
    )
    .sort((a, b) => a.stop_order - b.stop_order)

  if (stops.length === 0) {
    return (
      <div className="routes-map-empty">
        <div>
          <MapPinned size={30} />

          <strong>Chưa có dữ liệu bản đồ</strong>

          <span>
            Tuyến đường cần có tọa độ latitude và longitude
            trong bảng route_stops.
          </span>
        </div>
      </div>
    )
  }

  const latitudes = stops.map((stop) => Number(stop.latitude))
  const longitudes = stops.map((stop) => Number(stop.longitude))

  const minLat = Math.min(...latitudes)
  const maxLat = Math.max(...latitudes)

  const minLng = Math.min(...longitudes)
  const maxLng = Math.max(...longitudes)

  const latRange = maxLat - minLat || 0.001
  const lngRange = maxLng - minLng || 0.001

  const points = stops.map((stop) => ({
    ...stop,
    x:
      12 +
      ((Number(stop.longitude) - minLng) / lngRange) * 76,
    y:
      12 +
      ((maxLat - Number(stop.latitude)) / latRange) * 76,
  }))

  const path = points
    .map(
      (point, index) =>
        `${index === 0 ? 'M' : 'L'} ${point.x} ${point.y}`,
    )
    .join(' ')

  return (
    <>
      <div className="routes-map-container-mock">
        <svg
          className="routes-map-svg"
          viewBox="0 0 100 100"
          preserveAspectRatio="none"
          role="img"
          aria-label={`Sơ đồ tuyến ${route.route_name}`}
        >
          <path
            d={path}
            className="routes-map-route-line"
          />

          {points.map((point, index) => (
            <g key={point.stop_id}>
              <circle
                cx={point.x}
                cy={point.y}
                r="2.2"
                className="routes-map-stop-circle"
              />

              <text
                x={point.x}
                y={point.y - 4}
                textAnchor="middle"
                className="routes-map-stop-label"
              >
                {index + 1}
              </text>
            </g>
          ))}
        </svg>
      </div>

      <div className="routes-map-legend">
        <span>
          <i className="routes-legend-stop" />
          Điểm dừng
        </span>

        <span>
          <i className="routes-legend-line" />
          Lộ trình theo thứ tự điểm dừng
        </span>
      </div>
    </>
  )
}

// ==============================
// TRANG QUẢN LÝ XE VÀ TUYẾN
// ==============================

export function RoutesPage() {
  const {
    buses,
    routes,
    trips,
    search,
    setSearch,
    selectedRoute,
    setSelectedRoute,
    refreshing,
    loading,
    error,
    reload,
  } = useRoutes()

  // State mở modal
  const [showAddTrip, setShowAddTrip] = useState(false)
  const [showAddBus, setShowAddBus] = useState(false)

  // ==============================
  // CHI TIẾT TUYẾN
  // ==============================

  const currentRouteDetails = useMemo(
    () =>
      routes.find(
        (route) => route.route_id === selectedRoute,
      ) ??
      routes[0] ??
      null,
    [routes, selectedRoute],
  )

  // ==============================
  // TÌM KIẾM ĐỘI XE ĐỘC LẬP
  // Không phụ thuộc selectedRoute
  // ==============================

  const vehicleList = useMemo(() => {
    const keyword = search.trim().toLowerCase()

    if (!keyword) {
      return buses
    }

    return buses.filter((bus) =>
      [
        bus.license_plate,
        bus.bus_code,
        bus.driverName,
        bus.teacherName,
        bus.routeName,
      ].some((value) =>
        String(value ?? '')
          .toLowerCase()
          .includes(keyword),
      ),
    )
  }, [buses, search])

  // ==============================
  // LOADING
  // ==============================

  if (loading) {
    return (
      <div className="routes-loading">
        <div className="routes-spinner" />
        <p>Đang tải dữ liệu từ Supabase...</p>
      </div>
    )
  }

  // ==============================
  // GIAO DIỆN
  // ==============================

  return (
    <div className="routes-page">

      {/* HEADER */}

      <header className="routes-header">
        <div>
          <h1>Xe &amp; tuyến đường</h1>

          <p>
            {buses.length} xe · {routes.length} tuyến ·
            Quản lý phương tiện và lộ trình
          </p>
        </div>

        <div className="routes-header-actions">
          <button
            type="button"
            className="routes-add-trip"
            onClick={() => setShowAddTrip(true)}
          >
            <Plus size={17} />
            Thêm chuyến
          </button>

          <button
            type="button"
            className="routes-refresh"
            onClick={() => void reload()}
            disabled={refreshing}
          >
            <RefreshCw
              size={16}
              className={
                refreshing ? 'routes-spin-icon' : ''
              }
            />

            Làm mới
          </button>
        </div>
      </header>

      {/* ERROR */}

      {error && (
        <div className="routes-error">
          <AlertCircle size={18} />

          <span>{error}</span>

          <button
            type="button"
            onClick={() => void reload()}
          >
            Thử lại
          </button>
        </div>
      )}

      {/* ĐỘI XE */}

      <section className="routes-panel routes-vehicle-panel">
        <div className="routes-panel-heading">
          <div>
            <h2>Đội xe · {buses.length} xe</h2>

            <p>
              Hiển thị tất cả phương tiện trong cơ sở dữ liệu
            </p>
          </div>

          <div className="routes-vehicle-actions">
            <label className="routes-search">
              <Search size={16} />

              <input
                type="text"
                value={search}
                onChange={(event) =>
                  setSearch(event.target.value)
                }
                placeholder="Tìm biển số, tài xế, tuyến..."
              />
            </label>

            <button
              type="button"
              className="routes-add-bus"
              onClick={() => setShowAddBus(true)}
            >
              <Plus size={17} />
              Thêm xe
            </button>
          </div>
        </div>

        <div className="routes-filter">
          <button
            type="button"
            className="active"
          >
            Tất cả xe ({buses.length})
          </button>
        </div>

        <div className="routes-table-wrap">
          <table className="routes-table routes-vehicle-table">
            <thead>
              <tr>
                <th>Biển số</th>
                <th>Số chỗ</th>
                <th>Tài xế</th>
                <th>Cô giáo</th>
                <th>Tuyến hôm nay</th>
                <th>Trạng thái</th>

                <th className="routes-action-heading">
                  Thao tác
                </th>
              </tr>
            </thead>

            <tbody>
              {vehicleList.map((bus) => (
                <VehicleRow
                  key={bus.bus_id}
                  bus={bus}
                />
              ))}

              {vehicleList.length === 0 && (
                <tr>
                  <td
                    colSpan={7}
                    className="routes-empty"
                  >
                    {buses.length === 0
                      ? 'Chưa có phương tiện trong cơ sở dữ liệu.'
                      : 'Không tìm thấy phương tiện phù hợp.'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="routes-table-footer">
          Đang hiển thị {vehicleList.length} / {buses.length} phương tiện
        </div>
      </section>

      {/* CHI TIẾT TUYẾN VÀ BẢN ĐỒ */}

      <div className="routes-content-grid-split">

        {/* CHI TIẾT TUYẾN */}

        <section className="routes-panel routes-detail-panel">
          <div className="routes-panel-heading">
            <div>
              <h2>
                {currentRouteDetails
                  ? `${currentRouteDetails.route_name} · Chi tiết tuyến`
                  : 'Chi tiết tuyến'}
              </h2>

              <p>
                Danh sách các điểm đón và trả học sinh
              </p>
            </div>

            <button
              type="button"
              className="routes-optimize-btn"
              disabled
              title="Chức năng tối ưu lộ trình chưa được tích hợp"
            >
              <Zap size={14} />
              Tối ưu lộ trình
            </button>
          </div>

          <div className="routes-filter">
            {routes.map((route) => (
              <button
                type="button"
                key={route.route_id}
                className={
                  currentRouteDetails?.route_id === route.route_id
                    ? 'active'
                    : ''
                }
                onClick={() =>
                  setSelectedRoute(route.route_id)
                }
              >
                {route.route_name}
              </button>
            ))}
          </div>

          <div className="routes-stop-list-styled">
            {currentRouteDetails?.stops
              ?.filter((stop) => stop.is_active)
              .map((stop, index) => (
                <div
                  className="routes-stop-item-styled"
                  key={stop.stop_id}
                >
                  <div className="routes-stop-number-badge">
                    {index + 1}
                  </div>

                  <div className="routes-stop-content">
                    <strong>{stop.stop_name}</strong>

                    <small>
                      {stop.address || 'Chưa có địa chỉ'}
                    </small>
                  </div>

                  <div className="routes-stop-time">
                    <Clock3 size={13} />

                    {stop.estimated_time
                      ? stop.estimated_time.slice(0, 5)
                      : '—'}
                  </div>
                </div>
              ))}

            {!currentRouteDetails?.stops?.some(
              (stop) => stop.is_active,
            ) && (
              <div className="routes-empty-box">
                Tuyến này chưa có điểm dừng hoạt động.
              </div>
            )}
          </div>

          {currentRouteDetails && (
            <div className="routes-detail-footer">
              <span>
                <Bus size={14} />
                {currentRouteDetails.busCount} xe có chuyến hôm nay
              </span>

              <span>
                <Users size={14} />
                {currentRouteDetails.activeBusCount} xe đang chạy
              </span>

              <span>
                <Clock3 size={14} />

                {currentRouteDetails.estimated_duration
                  ? `${currentRouteDetails.estimated_duration} phút`
                  : 'Chưa có thời lượng'}
              </span>
            </div>
          )}
        </section>

        {/* BẢN ĐỒ */}

        <section className="routes-panel routes-map-panel-right">
          <div className="routes-panel-heading">
            <div>
              <h2>Lộ trình tuyến đường</h2>

              <p>
                {currentRouteDetails?.route_name ??
                  'Chưa chọn tuyến'}
              </p>
            </div>

            <MapPinned size={20} color="#3568e8" />
          </div>

          {currentRouteDetails ? (
            <RouteMap route={currentRouteDetails} />
          ) : (
            <div className="routes-map-empty">
              Chưa có dữ liệu tuyến đường.
            </div>
          )}
        </section>
      </div>

      {/* CHUYẾN XE HÔM NAY */}

      <section className="routes-panel routes-trips-panel">
        <div className="routes-panel-heading">
          <div>
            <h2>Chuyến xe hôm nay</h2>

            <p>
              {trips.length} chuyến được lên lịch
            </p>
          </div>

          <Clock3 size={20} color="#3568e8" />
        </div>

        <div className="routes-trips-grid">
          {trips.map((trip) => (
            <article
              className="routes-trip-card"
              key={trip.trip_id}
            >
              <strong>
                {trip.buses?.license_plate ?? 'Chưa có xe'}
              </strong>

              <p>
                {trip.routes?.route_name ?? 'Chưa có tuyến'}
              </p>

              <p>
                {trip.drivers?.users?.full_name ??
                  'Chưa có tài xế'}
              </p>

              <StatusBadge status={trip.status} />
            </article>
          ))}

          {trips.length === 0 && (
            <div className="routes-empty-box">
              Hôm nay chưa có chuyến xe nào.
            </div>
          )}
        </div>
      </section>

      {/* MODAL THÊM CHUYẾN */}

      {showAddTrip && (
        <AddTripModal
          onClose={() => setShowAddTrip(false)}
          onSuccess={() => {
            setShowAddTrip(false)
            void reload()
          }}
        />
      )}

      {/* MODAL THÊM XE */}

      {showAddBus && (
        <AddBusModal
          onClose={() => setShowAddBus(false)}
          onSuccess={() => {
            setShowAddBus(false)
            void reload()
          }}
        />
      )}
    </div>
  )
}

export default RoutesPage
