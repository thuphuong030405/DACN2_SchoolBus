import { useState } from 'react'
import { AlertCircle, Bus, X } from 'lucide-react'

import {
  routesService,
  type CreateBusData,
} from '../services/routesService'

import './AddBusModal.css'

interface AddBusModalProps {
  onClose: () => void
  onSuccess: () => void
}

export function AddBusModal({
  onClose,
  onSuccess,
}: AddBusModalProps) {
  const [form, setForm] = useState<CreateBusData>({
    bus_code: '',
    license_plate: '',
    capacity: 30,
    vehicle_model: '',
    status: 'ACTIVE',
  })

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleChange = (
    field: keyof CreateBusData,
    value: string | number,
  ) => {
    setForm((previous) => ({
      ...previous,
      [field]: value,
    }))
  }

  const handleSubmit = async (
    event: React.FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()
    setError('')

    if (!form.bus_code.trim()) {
      setError('Vui lòng nhập mã xe.')
      return
    }

    if (!form.license_plate.trim()) {
      setError('Vui lòng nhập biển số xe.')
      return
    }

    if (!Number.isInteger(form.capacity) || form.capacity <= 0) {
      setError('Sức chứa phải là số nguyên lớn hơn 0.')
      return
    }

    try {
      setLoading(true)

      await routesService.createBus(form)

      onSuccess()
    } catch (err) {
      console.error(err)
      setError(
        err instanceof Error
          ? err.message
          : 'Không thể thêm xe. Vui lòng thử lại.',
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className="add-bus-overlay"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !loading) {
          onClose()
        }
      }}
    >
      <div
        className="add-bus-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="add-bus-heading"
      >
        <div className="add-bus-header">
          <div className="add-bus-heading">
            <div className="add-bus-icon">
              <Bus size={22} />
            </div>

            <div>
              <h2 id="add-bus-heading">Thêm phương tiện</h2>
              <p>Nhập thông tin phương tiện mới</p>
            </div>
          </div>

          <button
            type="button"
            className="add-bus-close"
            onClick={onClose}
            disabled={loading}
            aria-label="Đóng"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="add-bus-body">
            <div className="add-bus-form-group">
              <label htmlFor="bus-code">
                Mã xe <span>*</span>
              </label>

              <input
                id="bus-code"
                type="text"
                placeholder="Ví dụ: BUS001"
                value={form.bus_code}
                onChange={(event) =>
                  handleChange('bus_code', event.target.value)
                }
                disabled={loading}
              />
            </div>

            <div className="add-bus-form-group">
              <label htmlFor="license-plate">
                Biển số xe <span>*</span>
              </label>

              <input
                id="license-plate"
                type="text"
                placeholder="Ví dụ: 43A-12345"
                value={form.license_plate}
                onChange={(event) =>
                  handleChange('license_plate', event.target.value)
                }
                disabled={loading}
              />
            </div>

            <div className="add-bus-form-row">
              <div className="add-bus-form-group">
                <label htmlFor="bus-capacity">
                  Sức chứa <span>*</span>
                </label>

                <input
                  id="bus-capacity"
                  type="number"
                  min="1"
                  step="1"
                  value={form.capacity}
                  onChange={(event) =>
                    handleChange(
                      'capacity',
                      Number(event.target.value),
                    )
                  }
                  disabled={loading}
                />
              </div>

              <div className="add-bus-form-group">
                <label htmlFor="bus-status">Trạng thái</label>

                <select
                  id="bus-status"
                  value={form.status}
                  onChange={(event) =>
                    handleChange(
                      'status',
                      event.target.value as CreateBusData['status'],
                    )
                  }
                  disabled={loading}
                >
                  <option value="ACTIVE">Đang hoạt động</option>
                  <option value="MAINTENANCE">Đang bảo trì</option>
                  <option value="INACTIVE">Ngừng hoạt động</option>
                </select>
              </div>
            </div>

            <div className="add-bus-form-group">
              <label htmlFor="vehicle-model">
                Loại xe / Dòng xe
              </label>

              <input
                id="vehicle-model"
                type="text"
                placeholder="Ví dụ: Ford Transit"
                value={form.vehicle_model ?? ''}
                onChange={(event) =>
                  handleChange('vehicle_model', event.target.value)
                }
                disabled={loading}
              />
            </div>

            <div className="add-bus-note">
              <AlertCircle size={16} />
              <span>
                Tài xế, giáo viên và tuyến đường có thể được phân công
                sau khi tạo phương tiện.
              </span>
            </div>

            {error && (
              <div className="add-bus-error">
                <AlertCircle size={17} />
                <span>{error}</span>
              </div>
            )}
          </div>

          <div className="add-bus-footer">
            <button
              type="button"
              className="add-bus-cancel"
              onClick={onClose}
              disabled={loading}
            >
              Hủy
            </button>

            <button
              type="submit"
              className="add-bus-submit"
              disabled={loading}
            >
              {loading ? 'Đang lưu...' : 'Thêm phương tiện'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}