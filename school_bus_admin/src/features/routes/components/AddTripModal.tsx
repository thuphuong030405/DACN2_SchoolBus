import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import { AlertCircle, Plus, X } from 'lucide-react'

import {
  createTrip,
  getTripFormOptions,
  type TripFormData,
  type TripFormOptions,
} from '../services/tripService'

import './AddTripModal.css'

interface AddTripModalProps {
  onClose: () => void
  onSuccess: () => void | Promise<void>
}

function getTodayDate(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')

  return `${year}-${month}-${day}`
}

const initialForm: TripFormData = {
  bus_id: '',
  route_id: '',
  driver_id: '',
  teacher_id: '',
  trip_date: getTodayDate(),
  trip_type: 'MORNING',
}

export function AddTripModal({
  onClose,
  onSuccess,
}: AddTripModalProps) {
  const [form, setForm] = useState<TripFormData>(initialForm)

  const [options, setOptions] = useState<TripFormOptions>({
    buses: [],
    routes: [],
    drivers: [],
    teachers: [],
  })

  const [loadingOptions, setLoadingOptions] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false

    async function loadOptions() {
      try {
        setLoadingOptions(true)
        setError('')

        const result = await getTripFormOptions()

        if (!cancelled) {
          setOptions(result)
        }
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof Error
              ? err.message
              : 'Không thể tải dữ liệu biểu mẫu.',
          )
        }
      } finally {
        if (!cancelled) {
          setLoadingOptions(false)
        }
      }
    }

    void loadOptions()

    return () => {
      cancelled = true
    }
  }, [])

  function updateForm<K extends keyof TripFormData>(
    key: K,
    value: TripFormData[K],
  ) {
    setForm((previous) => ({
      ...previous,
      [key]: value,
    }))
  }

  const hasOptions =
    options.buses.length > 0 &&
    options.routes.length > 0 &&
    options.drivers.length > 0 &&
    options.teachers.length > 0

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ) {
    event.preventDefault()

    if (saving) return

    setError('')

    if (
      !form.bus_id ||
      !form.route_id ||
      !form.driver_id ||
      !form.teacher_id ||
      !form.trip_date ||
      !form.trip_type
    ) {
      setError('Vui lòng nhập đầy đủ thông tin chuyến xe.')
      return
    }

    try {
      setSaving(true)

      await createTrip(form)

      // Thông báo và tải lại danh sách ở trang cha.
      await onSuccess()

      onClose()
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Có lỗi xảy ra khi lưu chuyến xe.',
      )
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="add-trip-overlay"
      onMouseDown={(event) => {
        if (
          event.target === event.currentTarget &&
          !saving
        ) {
          onClose()
        }
      }}
    >
      <section
        className="add-trip-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="add-trip-title"
      >
        {/* HEADER */}
        <header className="add-trip-header">
          <div>
            <h2 id="add-trip-title">Thêm chuyến xe</h2>
            <p>Tạo lịch trình mới cho phương tiện</p>
          </div>

          <button
            type="button"
            className="add-trip-close"
            onClick={onClose}
            disabled={saving}
            aria-label="Đóng"
          >
            <X size={19} />
          </button>
        </header>

        {/* BODY */}
        {loadingOptions ? (
          <div className="add-trip-loading">
            <span className="add-trip-spinner" />
            <p>Đang tải dữ liệu từ Supabase...</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="add-trip-grid">
              {/* PHƯƠNG TIỆN */}
              <div className="add-trip-field">
                <label htmlFor="trip-bus">
                  Phương tiện *
                </label>

                <select
                  id="trip-bus"
                  value={form.bus_id}
                  onChange={(event) =>
                    updateForm('bus_id', event.target.value)
                  }
                  required
                >
                  <option value="">-- Chọn xe --</option>

                  {options.buses.map((bus) => (
                    <option
                      key={bus.bus_id}
                      value={bus.bus_id}
                    >
                      {bus.license_plate} ({bus.bus_code})
                    </option>
                  ))}
                </select>
              </div>

              {/* TUYẾN ĐƯỜNG */}
              <div className="add-trip-field">
                <label htmlFor="trip-route">
                  Tuyến đường *
                </label>

                <select
                  id="trip-route"
                  value={form.route_id}
                  onChange={(event) =>
                    updateForm('route_id', event.target.value)
                  }
                  required
                >
                  <option value="">-- Chọn tuyến --</option>

                  {options.routes.map((route) => (
                    <option
                      key={route.route_id}
                      value={route.route_id}
                    >
                      {route.route_name} ({route.route_code})
                    </option>
                  ))}
                </select>
              </div>

              {/* TÀI XẾ */}
              <div className="add-trip-field">
                <label htmlFor="trip-driver">
                  Tài xế *
                </label>

                <select
                  id="trip-driver"
                  value={form.driver_id}
                  onChange={(event) =>
                    updateForm('driver_id', event.target.value)
                  }
                  required
                >
                  <option value="">-- Chọn tài xế --</option>

                  {options.drivers.map((driver) => (
                    <option
                      key={driver.driver_id}
                      value={driver.driver_id}
                    >
                      {driver.full_name} ({driver.driver_code})
                    </option>
                  ))}
                </select>
              </div>

              {/* GIÁO VIÊN */}
              <div className="add-trip-field">
                <label htmlFor="trip-teacher">
                  Giáo viên *
                </label>

                <select
                  id="trip-teacher"
                  value={form.teacher_id}
                  onChange={(event) =>
                    updateForm('teacher_id', event.target.value)
                  }
                  required
                >
                  <option value="">-- Chọn giáo viên --</option>

                  {options.teachers.map((teacher) => (
                    <option
                      key={teacher.teacher_id}
                      value={teacher.teacher_id}
                    >
                      {teacher.full_name} ({teacher.teacher_code})
                    </option>
                  ))}
                </select>
              </div>

              {/* NGÀY CHẠY */}
              <div className="add-trip-field">
                <label htmlFor="trip-date">
                  Ngày chạy *
                </label>

                <input
                  id="trip-date"
                  type="date"
                  value={form.trip_date}
                  onChange={(event) =>
                    updateForm('trip_date', event.target.value)
                  }
                  required
                />
              </div>

              {/* BUỔI CHẠY */}
              <div className="add-trip-field">
                <label htmlFor="trip-type">
                  Buổi chạy *
                </label>

                <select
                  id="trip-type"
                  value={form.trip_type}
                  onChange={(event) =>
                    updateForm(
                      'trip_type',
                      event.target.value as TripFormData['trip_type'],
                    )
                  }
                  required
                >
                  <option value="MORNING">Buổi sáng</option>
                  <option value="AFTERNOON">Buổi chiều</option>
                </select>
              </div>
            </div>

            {/* TRẠNG THÁI */}
            <div className="add-trip-status">
              <span>Trạng thái khi tạo</span>

              <span className="add-trip-status-badge">
                Chờ khởi hành
              </span>
            </div>

            {/* ERROR */}
            {error && (
              <div className="add-trip-error">
                <AlertCircle size={17} />
                <span>{error}</span>
              </div>
            )}

            {/* EMPTY OPTIONS */}
            {!hasOptions && !error && (
              <div className="add-trip-error">
                <AlertCircle size={17} />
                <span>
                  Cần có ít nhất một xe, tuyến, tài xế và giáo viên
                  để tạo chuyến.
                </span>
              </div>
            )}

            {/* ACTIONS */}
            <footer className="add-trip-actions">
              <button
                type="button"
                className="add-trip-cancel"
                onClick={onClose}
                disabled={saving}
              >
                Hủy
              </button>

              <button
                type="submit"
                className="add-trip-submit"
                disabled={saving || !hasOptions}
              >
                <Plus size={17} />

                {saving ? 'Đang lưu...' : 'Lưu chuyến xe'}
              </button>
            </footer>
          </form>
        )}
      </section>
    </div>
  )
}

export default AddTripModal