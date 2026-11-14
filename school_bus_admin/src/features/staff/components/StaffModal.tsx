import { useEffect, useState } from 'react'
import { X } from 'lucide-react'
import type { StaffFormPayload, StaffMember, StaffRole } from '../types'

interface StaffModalProps {
  open: boolean
  editingStaff: StaffMember | null
  isSubmitting: boolean
  onClose: () => void
  onSubmit: (payload: StaffFormPayload) => void
}

export function StaffModal({
  open,
  editingStaff,
  isSubmitting,
  onClose,
  onSubmit,
}: StaffModalProps) {
  const [role, setRole] = useState<StaffRole>('DRIVER')
  const [fullName, setFullName] = useState('')
  const [code, setCode] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [licenseNumber, setLicenseNumber] = useState('')
  const [licenseExpiry, setLicenseExpiry] = useState('')
  const [department, setDepartment] = useState('')

  useEffect(() => {
    if (editingStaff) {
      setRole(editingStaff.role)
      setFullName(editingStaff.full_name)
      setCode(editingStaff.code)
      setPhone(editingStaff.phone ?? '')
      setEmail(editingStaff.email)
      setLicenseNumber(editingStaff.license_number ?? '')
      setLicenseExpiry(editingStaff.license_expiry ?? '')
      setDepartment(editingStaff.department ?? '')
    } else {
      setRole('DRIVER')
      setFullName('')
      setCode('')
      setPhone('')
      setEmail('')
      setLicenseNumber('')
      setLicenseExpiry('')
      setDepartment('')
    }
  }, [editingStaff, open])

  if (!open) return null

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSubmit({
      role,
      full_name: fullName.trim(),
      code: code.trim(),
      phone: phone.trim(),
      email: email.trim(),
      license_number: role === 'DRIVER' ? licenseNumber.trim() : undefined,
      license_expiry: role === 'DRIVER' ? licenseExpiry : undefined,
      department: role === 'TEACHER' ? department.trim() : undefined,
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4 backdrop-blur-[1px]">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-xl">
        <div className="mb-5 flex items-center justify-between">
          <h3 className="text-lg font-bold text-slate-900">
            {editingStaff ? 'Chỉnh sửa hồ sơ nhân sự' : 'Thêm nhân sự mới'}
          </h3>
          <button
            onClick={onClose}
            className="grid size-8 place-items-center rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-600"
          >
            <X className="size-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {!editingStaff && (
            <div>
              <label className="mb-1.5 block text-xs font-semibold text-slate-700">
                Vai trò
              </label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setRole('DRIVER')}
                  className={`rounded-xl border py-2 text-xs font-semibold transition ${
                    role === 'DRIVER'
                      ? 'border-blue-600 bg-blue-50 text-blue-700'
                      : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                  }`}
                >
                  Tài xế
                </button>
                <button
                  type="button"
                  onClick={() => setRole('TEACHER')}
                  className={`rounded-xl border py-2 text-xs font-semibold transition ${
                    role === 'TEACHER'
                      ? 'border-amber-500 bg-amber-50 text-amber-700'
                      : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                  }`}
                >
                  Bảo mẫu
                </button>
              </div>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-xs font-semibold text-slate-700">
                Mã nhân sự *
              </label>
              <input
                required
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder={role === 'DRIVER' ? 'TX-015' : 'BM-016'}
                className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-semibold text-slate-700">
                Số điện thoại *
              </label>
              <input
                required
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="0905123456"
                className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="mb-1 block text-xs font-semibold text-slate-700">
              Họ và tên *
            </label>
            <input
              required
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Nguyễn Văn A"
              className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
            />
          </div>

          <div>
            <label className="mb-1 block text-xs font-semibold text-slate-700">
              Email đăng nhập *
            </label>
            <input
              required
              type="email"
              disabled={!!editingStaff}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="nhanvien@busantoan.edu.vn"
              className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500 disabled:bg-slate-50 disabled:text-slate-400"
            />
          </div>

          {role === 'DRIVER' ? (
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-700">
                  Số GPLX *
                </label>
                <input
                  required
                  value={licenseNumber}
                  onChange={(e) => setLicenseNumber(e.target.value)}
                  placeholder="790123456789"
                  className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-700">
                  Hạn GPLX
                </label>
                <input
                  type="date"
                  value={licenseExpiry}
                  onChange={(e) => setLicenseExpiry(e.target.value)}
                  className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
                />
              </div>
            </div>
          ) : (
            <div>
              <label className="mb-1 block text-xs font-semibold text-slate-700">
                Bộ phận / Tổ chuyên môn
              </label>
              <input
                value={department}
                onChange={(e) => setDepartment(e.target.value)}
                placeholder="Tổ Bảo mẫu Tiểu học"
                className="h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
              />
            </div>
          )}

          <div className="flex justify-end gap-2 pt-3">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border border-slate-200 px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-50"
            >
              Hủy
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="rounded-xl bg-blue-600 px-4 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {isSubmitting ? 'Đang lưu...' : editingStaff ? 'Lưu thay đổi' : 'Thêm nhân sự'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}