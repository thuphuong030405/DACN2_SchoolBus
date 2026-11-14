import type { AbsenceRequest } from '../types'
import './AbsenceDetail.css'

interface AbsenceDetailProps {
  request: AbsenceRequest | null
  adminNote: string
  processing: boolean
  onAdminNoteChange: (value: string) => void
  onApprove: () => void
  onReject: () => void
}

function formatDate(date: string) {
  if (!date) return '--'

  const parsed = new Date(`${date.slice(0, 10)}T00:00:00`)

  return Number.isNaN(parsed.getTime())
    ? date
    : parsed.toLocaleDateString('vi-VN')
}

function formatDateTime(date: string) {
  if (!date) return '--'

  const parsed = new Date(date)

  return Number.isNaN(parsed.getTime())
    ? date
    : parsed.toLocaleString('vi-VN')
}

export default function AbsenceDetail({
  request,
  adminNote,
  processing,
  onAdminNoteChange,
  onApprove,
  onReject,
}: AbsenceDetailProps) {
  if (!request) {
    return (
      <aside className="leave-detail-panel leave-detail-empty">
        <div className="leave-detail-empty-icon">▤</div>
        <h3>Chưa chọn đơn xin nghỉ</h3>
        <p>Chọn một đơn trong danh sách để xem thông tin chi tiết.</p>
      </aside>
    )
  }

  const isPending = request.status === 'PENDING'

  return (
    <aside className="leave-detail-panel">
      <div className="leave-detail-header">
        <div>
          <h2>Chi tiết đơn nghỉ</h2>
          <p>Thông tin yêu cầu xin nghỉ của học sinh</p>
        </div>

        <span
          className={`leave-status leave-status-${request.status.toLowerCase()}`}
        >
          <span className="leave-status-dot" />
          {request.status === 'PENDING'
            ? 'Chờ duyệt'
            : request.status === 'APPROVED'
              ? 'Đã duyệt'
              : 'Từ chối'}
        </span>
      </div>

      <div className="leave-detail-student">
        <div className="leave-detail-avatar">
          {request.studentName.charAt(0).toUpperCase()}
        </div>

        <div>
          <h3>{request.studentName}</h3>
          <p>{request.studentClass}</p>
        </div>
      </div>

      <div className="leave-detail-section">
        <h4>Thông tin đơn xin nghỉ</h4>

        <div className="leave-detail-info">
          <div className="leave-info-item">
            <span>Phụ huynh</span>
            <strong>{request.parentName}</strong>
          </div>

          <div className="leave-info-item">
            <span>Ngày nghỉ</span>
            <strong>{formatDate(request.date)}</strong>
          </div>

          <div className="leave-info-item">
            <span>Buổi nghỉ</span>
            <strong>
              {request.session === 'MORNING'
                ? 'Buổi sáng'
                : 'Buổi chiều'}
            </strong>
          </div>

          <div className="leave-info-item">
            <span>Thời gian gửi</span>
            <strong>{formatDateTime(request.submittedAt)}</strong>
          </div>
        </div>
      </div>

      <div className="leave-detail-section">
        <h4>Lý do xin nghỉ</h4>

        <div className="leave-reason-box">
          {request.reason || 'Không có nội dung lý do.'}
        </div>
      </div>

      <div className="leave-detail-section">
        <h4>Thông tin tuyến xe</h4>

        <div className="leave-route-box">
          <span className="leave-route-icon">🚌</span>
          <div>
            <strong>Tuyến xe của học sinh</strong>
            <p>{request.routeInfo}</p>
          </div>
        </div>
      </div>

      {request.status === 'REJECTED' && request.rejectionNote && (
        <div className="leave-detail-section">
          <h4>Lý do từ chối</h4>

          <div className="leave-rejection-note">
            {request.rejectionNote}
          </div>
        </div>
      )}

      {isPending && (
        <div className="leave-detail-section">
          <h4>Ghi chú của quản trị viên</h4>

          <textarea
            className="leave-admin-note"
            placeholder="Nhập lý do nếu từ chối đơn..."
            value={adminNote}
            onChange={(event) => onAdminNoteChange(event.target.value)}
            rows={4}
            disabled={processing}
          />

          <p className="leave-note-hint">
            Vui lòng nhập lý do khi từ chối đơn xin nghỉ.
          </p>
        </div>
      )}

      {isPending && (
        <div className="leave-detail-actions">
          <button
            type="button"
            className="leave-reject-btn"
            onClick={onReject}
            disabled={processing}
          >
            {processing ? 'Đang xử lý...' : 'Từ chối đơn'}
          </button>

          <button
            type="button"
            className="leave-approve-btn"
            onClick={onApprove}
            disabled={processing}
          >
            {processing ? 'Đang xử lý...' : '✓ Duyệt đơn'}
          </button>
        </div>
      )}

      {!isPending && (
        <div className="leave-processed-message">
          {request.status === 'APPROVED'
            ? 'Đơn xin nghỉ này đã được duyệt.'
            : 'Đơn xin nghỉ này đã bị từ chối.'}
        </div>
      )}
    </aside>
  )
}