import { useMemo, useState } from 'react'
import { useChildRequests, useReviewRequest } from '../hooks/useStudents'
import type { ChildRequest, StudentRow } from '../types'
import { Modal } from './Modal'

const REL_LABEL: Record<string, string> = {
  FATHER: 'Bố',
  MOTHER: 'Mẹ',
  GUARDIAN: 'Người giám hộ',
  OTHER: 'Khác',
}
const GENDER_LABEL: Record<string, string> = { MALE: 'Nam', FEMALE: 'Nữ', OTHER: 'Khác' }

const fmtDob = (d: string | null) => (d ? d.split('-').reverse().join('/') : '—')

const norm = (s: string) =>
  s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').toLowerCase().trim()

/** Chọn học sinh có sẵn để gộp (khi phụ huynh đăng ký trùng một em đã được nhà trường nhập). */
function MergeDialog({
  request,
  students,
  onClose,
}: {
  request: ChildRequest
  students: StudentRow[]
  onClose: () => void
}) {
  const review = useReviewRequest()
  const [q, setQ] = useState(request.fullName)
  const [pickedId, setPickedId] = useState('')

  const list = useMemo(() => {
    const k = norm(q)
    return students
      .filter((s) => !k || norm(s.fullName).includes(k) || norm(s.code).includes(k))
      .slice(0, 30)
  }, [students, q])

  return (
    <Modal title="Gộp vào học sinh có sẵn" onClose={onClose}>
      <p className="text-sm text-slate-500">
        Phụ huynh <b className="text-[#0F172A]">{request.parentName}</b> đăng ký em{' '}
        <b className="text-[#0F172A]">{request.fullName}</b>. Chọn đúng em đó trong danh sách của trường.
      </p>

      <input
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Tìm theo tên hoặc mã học sinh..."
        className="mt-3 h-10 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-blue-500"
      />

      <div className="mt-2 max-h-56 overflow-y-auto rounded-xl border border-slate-200">
        {list.length === 0 && <p className="p-3 text-sm text-slate-400">Không tìm thấy học sinh</p>}
        {list.map((s) => (
          <button
            key={s.id}
            type="button"
            onClick={() => setPickedId(s.id)}
            className={`flex w-full flex-col items-start border-b border-slate-100 px-3 py-2 text-left last:border-0 hover:bg-slate-50 ${
              pickedId === s.id ? 'bg-blue-50' : ''
            }`}
          >
            <span className="text-sm font-semibold text-[#0F172A]">{s.fullName}</span>
            <span className="text-xs text-slate-400">
              Mã {s.code || '—'} · Lớp {s.className || '—'}
              {s.hasParent ? ` · đã có phụ huynh: ${s.parentName}` : ''}
            </span>
          </button>
        ))}
      </div>

      {review.error && (
        <p className="mt-3 rounded-lg bg-rose-50 p-2 text-sm text-rose-600">
          {(review.error as Error).message}
        </p>
      )}

      <div className="mt-4 flex justify-end gap-2">
        <button
          type="button"
          onClick={onClose}
          className="h-10 rounded-xl border border-slate-200 px-4 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          Hủy
        </button>
        <button
          type="button"
          disabled={!pickedId || review.isPending}
          onClick={() =>
            review.mutate(
              {
                studentId: request.studentId,
                parentId: request.parentId,
                approve: true,
                mergeIntoId: pickedId,
              },
              { onSuccess: onClose },
            )
          }
          className="h-10 rounded-xl bg-[#2563EB] px-4 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
        >
          {review.isPending ? 'Đang gộp...' : 'Gộp và duyệt'}
        </button>
      </div>
    </Modal>
  )
}

export function ChildRequestsPanel({ students }: { students: StudentRow[] }) {
  const { data = [], isLoading, error } = useChildRequests()
  const review = useReviewRequest()
  const [mergeFor, setMergeFor] = useState<ChildRequest | null>(null)

  return (
    <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
      <h2 className="text-base font-bold text-[#0F172A]">Yêu cầu chờ duyệt · {data.length}</h2>
      <p className="mt-1 text-xs text-slate-400">
        Phụ huynh tự đăng ký thông tin con trong ứng dụng. Nhà trường kiểm tra rồi duyệt.
      </p>

      {error && (
        <p className="mt-3 rounded-lg bg-rose-50 p-2 text-sm text-rose-600">
          Không tải được yêu cầu: {(error as Error).message}
        </p>
      )}
      {review.error && !mergeFor && (
        <p className="mt-3 rounded-lg bg-rose-50 p-2 text-sm text-rose-600">
          {(review.error as Error).message}
        </p>
      )}
      {isLoading && <p className="py-10 text-center text-slate-400">Đang tải...</p>}
      {!isLoading && data.length === 0 && (
        <p className="py-10 text-center text-slate-400">Không có yêu cầu nào đang chờ</p>
      )}

      <div className="mt-4 space-y-3">
        {data.map((r) => (
          <div
            key={`${r.studentId}-${r.parentId}`}
            className="flex flex-wrap items-start justify-between gap-4 rounded-xl border border-slate-200 p-4"
          >
            <div className="min-w-0 space-y-1 text-sm">
              <div className="text-base font-bold text-[#0F172A]">{r.fullName || '—'}</div>
              <div className="text-slate-500">
                Sinh {fmtDob(r.dateOfBirth)} ·{' '}
                {r.gender ? GENDER_LABEL[r.gender] ?? r.gender : 'Chưa rõ giới tính'} · Lớp{' '}
                {r.className || '—'}
              </div>
              <div className="text-slate-700">
                Phụ huynh: <b>{r.parentName}</b> ({REL_LABEL[r.relationship] ?? r.relationship})
              </div>
              <div className="text-xs text-slate-400">
                {[r.parentPhone, r.parentEmail].filter(Boolean).join(' · ') || '—'}
              </div>
            </div>

            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                disabled={review.isPending}
                onClick={() =>
                  review.mutate({ studentId: r.studentId, parentId: r.parentId, approve: true })
                }
                className="h-9 rounded-xl bg-[#2563EB] px-4 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              >
                Duyệt
              </button>
              <button
                type="button"
                onClick={() => setMergeFor(r)}
                className="h-9 rounded-xl border border-slate-200 px-4 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              >
                Gộp vào học sinh có sẵn
              </button>
              <button
                type="button"
                disabled={review.isPending}
                onClick={() => {
                  const note = window.prompt(
                    `Lý do từ chối đăng ký "${r.fullName}" của ${r.parentName} (không bắt buộc):`,
                  )
                  if (note === null) return // bấm Hủy
                  review.mutate({
                    studentId: r.studentId,
                    parentId: r.parentId,
                    approve: false,
                    note,
                  })
                }}
                className="h-9 rounded-xl border border-rose-200 px-4 text-sm font-semibold text-rose-600 hover:bg-rose-50 disabled:opacity-50"
              >
                Từ chối
              </button>
            </div>
          </div>
        ))}
      </div>

      {mergeFor && (
        <MergeDialog request={mergeFor} students={students} onClose={() => setMergeFor(null)} />
      )}
    </section>
  )
}