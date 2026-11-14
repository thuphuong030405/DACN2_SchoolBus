import { useEffect, useMemo, useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import {
  RefreshCw,
  Plus,
  MoreVertical,
  Pencil,
  ArrowLeftRight,
  Phone,
  AlertTriangle,
  Heart,
  LifeBuoy,
  Users,
} from 'lucide-react'
import { useStaff } from './hooks/useStaff'
import { StaffModal } from './components/StaffModal'
import { ReassignModal } from './components/ReassignModal'
import type { DocStatus, StaffMember } from './types'

type RoleFilter = 'ALL' | 'DRIVER' | 'TEACHER'

function getInitials(fullName: string): string {
  const parts = fullName.trim().split(/\s+/)
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
  return (parts[parts.length - 2][0] + parts[parts.length - 1][0]).toUpperCase()
}

const avatarThemes = [
  'bg-blue-100 text-blue-700',
  'bg-amber-100 text-amber-700',
  'bg-emerald-100 text-emerald-700',
  'bg-rose-100 text-rose-700',
]

function maskPhone(phone: string | null): string {
  if (!phone) return 'Chưa cập nhật'
  const clean = phone.replace(/\s+/g, '')
  if (clean.length < 7) return clean
  return `${clean.slice(0, 2)}•• ••• ${clean.slice(-3)}`
}

const docBadgeStyle: Record<DocStatus, string> = {
  VALID: 'bg-emerald-100 text-emerald-700',
  EXPIRING_SOON: 'bg-amber-100 text-amber-700',
  EXPIRED: 'bg-red-100 text-red-600',
}

export function StaffPage() {
  const queryClient = useQueryClient()

  const {
    staffQuery,
    busesQuery,
    routesQuery,
    createMutation,
    updateMutation,
    reassignMutation,
  } = useStaff()

  const [roleFilter, setRoleFilter] = useState<RoleFilter>('ALL')
  const [selectedStaffId, setSelectedStaffId] = useState<string | null>(null)

  // Modal states
  const [isStaffModalOpen, setIsStaffModalOpen] = useState(false)
  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null)
  const [isReassignOpen, setIsReassignOpen] = useState(false)

  const staffList = staffQuery.data ?? []

  useEffect(() => {
    if (staffList.length > 0 && !selectedStaffId) {
      setSelectedStaffId(staffList[0].id)
    }
  }, [staffList, selectedStaffId])

  const stats = useMemo(() => {
    const drivers = staffList.filter((s) => s.role === 'DRIVER')
    const teachers = staffList.filter((s) => s.role === 'TEACHER')
    const expiringDocs = staffList.filter(
      (s) =>
        s.primary_doc_status === 'EXPIRING_SOON' ||
        s.primary_doc_status === 'EXPIRED'
    )

    return {
      total: staffList.length,
      driverCount: drivers.length,
      driverRunning: drivers.filter((d) => d.status === 'RUNNING').length,
      teacherCount: teachers.length,
      teacherRunning: teachers.filter((t) => t.status === 'RUNNING').length,
      expiringCount: expiringDocs.length,
    }
  }, [staffList])

  const filteredStaff = useMemo(() => {
    if (roleFilter === 'ALL') return staffList
    return staffList.filter((item) => item.role === roleFilter)
  }, [staffList, roleFilter])

  const selectedStaff = useMemo(
    () => staffList.find((s) => s.id === selectedStaffId) ?? filteredStaff[0] ?? null,
    [staffList, selectedStaffId, filteredStaff]
  )

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: ['staff-list'] })
    queryClient.invalidateQueries({ queryKey: ['fleet-buses'] })
    queryClient.invalidateQueries({ queryKey: ['fleet-routes'] })
  }

  const handleOpenAdd = () => {
    setEditingStaff(null)
    setIsStaffModalOpen(true)
  }

  const handleOpenEdit = (staff: StaffMember) => {
    setEditingStaff(staff)
    setIsStaffModalOpen(true)
  }

  const handleSaveStaff = async (payload: any) => {
    try {
      if (editingStaff) {
        await updateMutation.mutateAsync({ staff: editingStaff, payload })
        alert('Cập nhật thông tin nhân sự thành công!')
      } else {
        await createMutation.mutateAsync(payload)
        alert('Thêm nhân sự thành công!\nMật khẩu đăng nhập mặc định: BusAnToan@2026')
      }
      setIsStaffModalOpen(false)
    } catch (err: any) {
      const msg = err?.message || 'Có lỗi xảy ra khi lưu nhân sự'
      if (msg.includes('User already registered')) {
        alert('Lỗi: Email này đã tồn tại trong hệ thống. Vui lòng dùng email khác!')
      } else if (msg.includes('duplicate key')) {
        alert('Lỗi: Mã nhân sự, Số điện thoại hoặc Số GPLX đã bị trùng!')
      } else {
        alert(`Lỗi: ${msg}`)
      }
    }
  }

  const handleConfirmReassign = async (
    busId: string,
    routeId: string,
    partnerId: string
  ) => {
    if (!selectedStaff) return
    try {
      await reassignMutation.mutateAsync({
        staff: selectedStaff,
        busId,
        routeId,
        partnerId,
      })
      setIsReassignOpen(false)
    } catch (err: any) {
      alert(`Lỗi phân công: ${err?.message || 'Không thể cập nhật dữ liệu'}`)
    }
  }

  return (
    <div className="flex min-h-[calc(100vh-80px)] flex-col gap-5">
      {/* HEADER (Đã đổi icon thông báo thành nút Reload) */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Tài xế &amp; bảo mẫu
          </h1>
          <p className="mt-0.5 text-xs text-slate-500">
            {stats.total} nhân sự · quản lý hồ sơ, giấy tờ và phân công
          </p>
        </div>

        <button
          type="button"
          onClick={handleRefresh}
          title="Làm mới dữ liệu"
          className="grid size-10 place-items-center rounded-xl border border-slate-200 bg-white text-slate-600 shadow-2xs transition hover:bg-slate-50"
        >
          <RefreshCw
            className={`size-4 ${staffQuery.isFetching ? 'animate-spin text-blue-600' : ''}`}
          />
        </button>
      </div>

      {/* 3 KPI SUMMARY CARDS */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        {/* Card 1: Tài xế */}
        <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
          <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-blue-50 text-blue-600">
            <LifeBuoy className="size-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">Tài xế</p>
            <p className="my-0.5 text-2xl font-extrabold text-slate-900">
              {stats.driverCount}
            </p>
            <span className="inline-block rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-semibold text-emerald-700">
              {stats.driverRunning} đang chạy
            </span>
          </div>
        </div>

        {/* Card 2: Bảo mẫu */}
        <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
          <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-amber-50 text-amber-500">
            <Heart className="size-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">Bảo mẫu</p>
            <p className="my-0.5 text-2xl font-extrabold text-slate-900">
              {stats.teacherCount}
            </p>
            <span className="inline-block rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-semibold text-emerald-700">
              {stats.teacherRunning} đang chạy
            </span>
          </div>
        </div>

        {/* Card 3: Sắp hết hạn giấy tờ */}
        <div className="flex items-center gap-4 rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
          <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-red-50 text-red-500">
            <AlertTriangle className="size-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">
              Sắp hết hạn giấy tờ
            </p>
            <p className="my-0.5 text-2xl font-extrabold text-slate-900">
              {stats.expiringCount}
            </p>
            <span className="inline-block rounded-full bg-red-100 px-2.5 py-0.5 text-[11px] font-semibold text-red-600">
              Trong 30 ngày
            </span>
          </div>
        </div>
      </div>

      {/* MAIN 2-COLUMN WORKSPACE */}
      <div className="grid flex-1 grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_340px]">
        {/* LEFT: STAFF TABLE */}
        <section className="flex flex-col justify-between rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
          <div>
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h2 className="text-base font-bold text-slate-900">
                Danh sách nhân sự
              </h2>

              <button
                onClick={handleOpenAdd}
                className="inline-flex items-center gap-1.5 rounded-xl bg-blue-600 px-4 py-2 text-xs font-semibold text-white shadow-xs transition hover:bg-blue-700"
              >
                <Plus className="size-4" />
                Thêm nhân sự
              </button>
            </div>

            {/* Filter Pills */}
            <div className="mb-4 flex flex-wrap items-center gap-2">
              <button
                onClick={() => setRoleFilter('ALL')}
                className={`rounded-full px-4 py-1.5 text-xs font-semibold transition ${
                  roleFilter === 'ALL'
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                }`}
              >
                Tất cả {stats.total}
              </button>

              <button
                onClick={() => setRoleFilter('DRIVER')}
                className={`rounded-full px-4 py-1.5 text-xs font-semibold transition ${
                  roleFilter === 'DRIVER'
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                }`}
              >
                Tài xế {stats.driverCount}
              </button>

              <button
                onClick={() => setRoleFilter('TEACHER')}
                className={`rounded-full px-4 py-1.5 text-xs font-semibold transition ${
                  roleFilter === 'TEACHER'
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                }`}
              >
                Bảo mẫu {stats.teacherCount}
              </button>
            </div>

            {/* Responsive Table */}
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left">
                <thead>
                  <tr className="border-b border-slate-100 text-[11px] font-semibold text-slate-400">
                    <th className="py-3 pl-3 pr-2">Họ tên</th>
                    <th className="px-2 py-3">Vai trò</th>
                    <th className="px-2 py-3">Điện thoại</th>
                    <th className="px-2 py-3">Phân công</th>
                    <th className="px-2 py-3">Giấy tờ / chứng chỉ</th>
                    <th className="py-3 pl-2 pr-3">Trạng thái</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-100 text-xs">
                  {staffQuery.isLoading && (
                    <tr>
                      <td colSpan={6} className="py-12 text-center text-slate-400">
                        Đang tải danh sách nhân sự...
                      </td>
                    </tr>
                  )}

                  {staffQuery.error && (
                    <tr>
                      <td colSpan={6} className="py-8 text-center text-red-500">
                        Lỗi tải dữ liệu: {(staffQuery.error as Error).message}
                      </td>
                    </tr>
                  )}

                  {!staffQuery.isLoading && filteredStaff.length === 0 && (
                    <tr>
                      <td colSpan={6} className="py-12 text-center text-slate-400">
                        <Users className="mx-auto mb-2 size-7 text-slate-300" />
                        Không có nhân sự nào trong danh mục này
                      </td>
                    </tr>
                  )}

                  {filteredStaff.map((staff, idx) => {
                    const isSelected = selectedStaff?.id === staff.id
                    const avatarClass = avatarThemes[idx % avatarThemes.length]

                    return (
                      <tr
                        key={staff.id}
                        onClick={() => setSelectedStaffId(staff.id)}
                        className={`cursor-pointer transition-colors ${
                          isSelected ? 'bg-blue-50/70' : 'hover:bg-slate-50/80'
                        }`}
                      >
                        <td className="py-3 pl-3 pr-2">
                          <div className="flex items-center gap-3">
                            <div
                              className={`grid size-9 shrink-0 place-items-center rounded-full text-xs font-bold ${avatarClass}`}
                            >
                              {getInitials(staff.full_name)}
                            </div>
                            <div className="min-w-0">
                              <p className="font-bold text-slate-800">
                                {staff.full_name}
                              </p>
                              <p className="text-[11px] text-slate-400">
                                {staff.code}
                              </p>
                            </div>
                          </div>
                        </td>

                        <td className="px-2 py-3">
                          {staff.role === 'DRIVER' ? (
                            <span className="inline-block rounded-full bg-blue-100 px-2.5 py-1 text-[11px] font-semibold text-blue-700">
                              Tài xế
                            </span>
                          ) : (
                            <span className="inline-block rounded-full bg-amber-100 px-2.5 py-1 text-[11px] font-semibold text-amber-700">
                              Bảo mẫu
                            </span>
                          )}
                        </td>

                        <td className="px-2 py-3 font-medium text-slate-700">
                          {maskPhone(staff.phone)}
                        </td>

                        <td className="px-2 py-3 text-slate-600">
                          {staff.role === 'DRIVER' ? (
                            staff.assigned_bus_plate ? (
                              <span>
                                {staff.assigned_bus_plate} ·{' '}
                                {staff.assigned_route_name ?? 'Chưa có tuyến'}
                              </span>
                            ) : (
                              <span className="text-slate-400">Chưa phân công</span>
                            )
                          ) : staff.assigned_route_name ? (
                            <span>{staff.assigned_route_name} · Đón &amp; trả</span>
                          ) : (
                            <span className="text-slate-400">Chưa phân công</span>
                          )}
                        </td>

                        <td className="px-2 py-3">
                          <p className="font-medium text-slate-700">
                            {staff.primary_doc_title}
                          </p>
                          <span
                            className={`mt-0.5 inline-block rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                              docBadgeStyle[staff.primary_doc_status]
                            }`}
                          >
                            {staff.primary_doc_expiry}
                          </span>
                        </td>

                        <td className="py-3 pl-2 pr-3">
                          <div className="flex items-center justify-between gap-2">
                            {staff.status === 'RUNNING' ? (
                              <span className="inline-block rounded-full bg-blue-100 px-2.5 py-1 text-[11px] font-semibold text-blue-700">
                                Đang chạy
                              </span>
                            ) : (
                              <span className="inline-block rounded-full bg-emerald-100 px-2.5 py-1 text-[11px] font-semibold text-emerald-700">
                                Sẵn sàng
                              </span>
                            )}

                            <button
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation()
                                setSelectedStaffId(staff.id)
                                handleOpenEdit(staff)
                              }}
                              className="rounded-lg p-1 text-slate-400 hover:bg-slate-200/60 hover:text-slate-600"
                            >
                              <MoreVertical className="size-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>

          <div className="mt-4 border-t border-slate-100 pt-3 text-xs text-slate-400">
            Hiển thị {filteredStaff.length} trên {stats.total} nhân sự
          </div>
        </section>

        {/* RIGHT: STAFF PROFILE DETAIL CARD */}
        <aside className="flex flex-col justify-between rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
          {selectedStaff ? (
            <div>
              <h2 className="mb-4 text-base font-bold text-slate-900">
                Hồ sơ nhân sự
              </h2>

              <div className="mb-5 flex items-center gap-3.5">
                <div className="grid size-14 shrink-0 place-items-center rounded-full bg-blue-100 text-lg font-bold text-blue-700">
                  {getInitials(selectedStaff.full_name)}
                </div>

                <div>
                  <h3 className="text-base font-bold text-slate-900">
                    {selectedStaff.full_name}
                  </h3>
                  <div className="mt-1 flex items-center gap-1.5">
                    {selectedStaff.role === 'DRIVER' ? (
                      <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-[11px] font-semibold text-blue-700">
                        Tài xế
                      </span>
                    ) : (
                      <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-[11px] font-semibold text-amber-700">
                        Bảo mẫu
                      </span>
                    )}
                    <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600">
                      {selectedStaff.code}
                    </span>
                  </div>
                </div>
              </div>

              <div className="mb-5 grid grid-cols-3 gap-2">
                <div className="rounded-xl bg-slate-50 px-2 py-3 text-center">
                  <p className="text-lg font-extrabold text-slate-900">
                    {selectedStaff.total_trips}
                  </p>
                  <p className="text-[11px] text-slate-500">chuyến</p>
                </div>

                <div className="rounded-xl bg-slate-50 px-2 py-3 text-center">
                  <p className="text-lg font-extrabold text-slate-900">
                    {selectedStaff.incidents_count}
                  </p>
                  <p className="text-[11px] text-slate-500">sự cố</p>
                </div>

                <div className="rounded-xl bg-slate-50 px-2 py-3 text-center">
                  <p className="text-lg font-extrabold text-slate-900">
                    {selectedStaff.on_time_rate}%
                  </p>
                  <p className="text-[11px] text-slate-500">đúng giờ</p>
                </div>
              </div>

              <div className="space-y-3 border-b border-slate-100 pb-4 text-xs">
                <div className="flex items-center justify-between">
                  <span className="text-slate-400">Điện thoại</span>
                  <span className="font-bold text-slate-800">
                    {maskPhone(selectedStaff.phone)}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-slate-400">Xe phụ trách</span>
                  <span className="font-bold text-slate-800">
                    {selectedStaff.assigned_bus_plate ?? 'Chưa phân công'}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-slate-400">
                    {selectedStaff.role === 'DRIVER'
                      ? 'Bảo mẫu đi cùng'
                      : 'Tài xế phụ trách'}
                  </span>
                  <span className="font-bold text-slate-800">
                    {selectedStaff.partner_name}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-slate-400">Tuyến</span>
                  <span className="font-bold text-slate-800">
                    {selectedStaff.assigned_route_name
                      ? `${selectedStaff.assigned_route_name} · Đón & trả`
                      : 'Chưa phân công'}
                  </span>
                </div>
              </div>

              <div className="pt-4">
                <p className="mb-3 text-xs font-bold text-slate-800">Giấy tờ</p>
                <div className="space-y-2.5">
                  {selectedStaff.documents.map((doc, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between gap-2 text-xs"
                    >
                      <span className="text-slate-600">{doc.name}</span>
                      <span
                        className={`shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-semibold ${
                          docBadgeStyle[doc.status]
                        }`}
                      >
                        {doc.expiryLabel}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="grid flex-1 place-items-center text-xs text-slate-400">
              Chọn một nhân sự để xem hồ sơ
            </div>
          )}

          {selectedStaff && (
            <div className="mt-6 flex items-center gap-2 pt-2">
              <button
                type="button"
                onClick={() => handleOpenEdit(selectedStaff)}
                className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-blue-600 px-3 py-2.5 text-xs font-semibold text-white shadow-xs transition hover:bg-blue-700"
              >
                <Pencil className="size-3.5" />
                Chỉnh sửa
              </button>

              <button
                type="button"
                onClick={() => setIsReassignOpen(true)}
                className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-50"
              >
                <ArrowLeftRight className="size-3.5" />
                Phân công lại
              </button>

              <a
                href={selectedStaff.phone ? `tel:${selectedStaff.phone}` : '#'}
                title={selectedStaff.phone ?? 'Chưa có số điện thoại'}
                className="grid size-10 shrink-0 place-items-center rounded-xl border border-slate-200 bg-white text-slate-700 transition hover:bg-slate-50"
              >
                <Phone className="size-4" />
              </a>
            </div>
          )}
        </aside>
      </div>

      {/* MODALS */}
      <StaffModal
        open={isStaffModalOpen}
        editingStaff={editingStaff}
        isSubmitting={createMutation.isPending || updateMutation.isPending}
        onClose={() => setIsStaffModalOpen(false)}
        onSubmit={handleSaveStaff}
      />

      <ReassignModal
        open={isReassignOpen}
        staff={selectedStaff}
        allStaff={staffList}
        buses={busesQuery.data ?? []}
        routes={routesQuery.data ?? []}
        isSubmitting={reassignMutation.isPending}
        onClose={() => setIsReassignOpen(false)}
        onSubmit={handleConfirmReassign}
      />
    </div>
  )
}

export default StaffPage