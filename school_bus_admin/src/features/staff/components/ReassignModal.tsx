import { useEffect, useState } from 'react'
import { X } from 'lucide-react'
import type { StaffMember } from '../types'

interface ReassignModalProps {
  open: boolean
  staff: StaffMember | null
  allStaff: StaffMember[]
  buses: { bus_id: string; bus_code: string; license_plate: string }[]
  routes: { route_id: string; route_code: string; route_name: string }[]
  isSubmitting: boolean
  onClose: () => void
  onSubmit: (busId: string, routeId: string, partnerId: string) => void
}

export function ReassignModal({
  open,
  staff,
  allStaff,
  buses,
  routes,
  isSubmitting,
  onClose,
  onSubmit,
}: ReassignModalProps) {
  const [busId, setBusId] = useState('')
  const [routeId, setRouteId] = useState('')
  const [partnerId, setPartnerId] = useState('')

  const partners = allStaff.filter((s) =>
    staff?.role === 'DRIVER' ? s.role === 'TEACHER' : s.role === 'DRIVER'
  )

  useEffect(() => {
    if (staff && open) {
      setBusId(staff.assigned_bus_id ?? buses[0]?.bus_id ?? '')
      setRouteId(staff.assigned_route_id ?? routes[0]?.route_id ?? '')
      setPartnerId(partners[0]?.id ?? '')
    }
  }, [staff, buses, routes, open])

  if (!open || !staff) return null

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (busId && routeId && partnerId) {
      onSubmit(busId, routeId, partnerId)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4 backdrop-blur-[1px]">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-slate-900">Phân công lại</h3>
            <p className="text-xs text-slate-500">
              {staff.full_name} ({staff.code})
            </p>
          </div>
          <button
            onClick={onClose}
            className="grid size-8 place-items-center rounded-lg text-slate-400 hover:bg-slate-100"
          >
            <X className="size-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="mb-1.5 block text-xs font-semibold text-slate-700">
              Xe phụ trách *
            </label>
            <select
              required
              value={busId}
              onChange={(e) => setBusId(e.target.value)}
              className="h-10 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none focus:border-blue-500"
            >
              {buses.map((b) => (
                <option key={b.bus_id} value={b.bus_id}>
                  {b.license_plate} ({b.bus_code})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-semibold text-slate-700">
              Tuyến đường *
            </label>
            <select
              required
              value={routeId}
              onChange={(e) => setRouteId(e.target.value)}
              className="h-10 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none focus:border-blue-500"
            >
              {routes.map((r) => (
                <option key={r.route_id} value={r.route_id}>
                  {r.route_name} ({r.route_code})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-semibold text-slate-700">
              {staff.role === 'DRIVER' ? 'Bảo mẫu đi cùng *' : 'Tài xế phụ trách *'}
            </label>
            <select
              required
              value={partnerId}
              onChange={(e) => setPartnerId(e.target.value)}
              className="h-10 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none focus:border-blue-500"
            >
              {partners.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.full_name} ({p.code})
                </option>
              ))}
            </select>
          </div>

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
              disabled={isSubmitting || !busId || !routeId || !partnerId}
              className="rounded-xl bg-blue-600 px-4 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {isSubmitting ? 'Đang cập nhật...' : 'Xác nhận phân công'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}