import { Check, ScanFace, Upload, User } from 'lucide-react'
import type { StudentRow } from '../types'

const STEPS = ['Nhìn thẳng', 'Quay trái', 'Quay phải']

export function FaceRegisterPanel({ student }: { student: StudentRow | null }) {
  return (
    <aside className="h-fit rounded-2xl border border-slate-200/80 bg-white p-5 shadow-2xs">
      <h2 className="text-base font-bold text-[#0F172A]">Đăng ký khuôn mặt</h2>

      {!student ? (
        <p className="mt-3 text-sm text-slate-400">
          Chọn một học sinh trong danh sách để xem trạng thái khuôn mặt.
        </p>
      ) : (
        <>
          <div className="mt-3 flex items-center gap-3">
            <span className="grid size-9 place-items-center rounded-full bg-rose-100 text-xs font-bold text-rose-700">
              {student.fullName.trim().split(/\s+/).slice(-2).map((w) => w[0]).join('').toUpperCase()}
            </span>
            <div className="leading-tight">
              <div className="font-semibold text-[#0F172A]">{student.fullName}</div>
              <div className="text-xs text-slate-400">
                Lớp {student.className || '—'} · Tuyến {student.routeCode}
              </div>
            </div>
          </div>

          {/* Khung camera (giai đoạn 1: chỉ hiển thị khung mẫu) */}
          <div className="relative mt-4 grid aspect-[4/3] place-items-center rounded-2xl bg-[#0F2150]">
            <div className="absolute left-4 top-4 size-6 rounded-tl-lg border-l-2 border-t-2 border-white" />
            <div className="absolute right-4 top-4 size-6 rounded-tr-lg border-r-2 border-t-2 border-white" />
            <div className="absolute bottom-4 left-4 size-6 rounded-bl-lg border-b-2 border-l-2 border-white" />
            <div className="absolute bottom-4 right-4 size-6 rounded-br-lg border-b-2 border-r-2 border-white" />
            <div className="grid h-3/4 w-1/2 place-items-center rounded-full border-2 border-dashed border-amber-300">
              <User className="size-12 text-blue-300/70" />
            </div>
          </div>

          <div className="mt-4 flex justify-between px-2">
            {STEPS.map((label, i) => {
              const done = student.faceCount > i
              return (
                <div key={label} className="flex flex-col items-center gap-1.5 text-xs">
                  <span
                    className={`grid size-8 place-items-center rounded-full border-2 font-bold ${
                      done
                        ? 'border-[#2563EB] bg-[#2563EB] text-white'
                        : 'border-slate-300 text-slate-400'
                    }`}
                  >
                    {done ? <Check className="size-4" /> : i + 1}
                  </span>
                  <span className={done ? 'font-semibold text-slate-700' : 'text-slate-400'}>
                    {label}
                  </span>
                </div>
              )
            })}
          </div>

          <div className="mt-4 flex items-center justify-between text-sm">
            <span className="text-slate-500">Vector hợp lệ</span>
            <span className="rounded-md bg-emerald-100 px-2 py-0.5 text-xs font-semibold text-emerald-700">
              {student.faceCount}/3 góc
            </span>
          </div>

          <div className="mt-4 rounded-xl bg-blue-50 p-3 text-xs text-blue-700">
            Chỉ lưu vector đặc trưng đã mã hóa, không lưu ảnh gốc.
          </div>

          <div className="mt-4 flex gap-2">
            <button
              type="button"
              onClick={() => alert('TODO: trích vector bằng MobileFaceNet')}
              className="inline-flex h-10 flex-1 items-center justify-center gap-1.5 rounded-xl bg-[#2563EB] text-sm font-semibold text-white hover:bg-blue-700"
            >
              <ScanFace className="size-4" /> Chụp &amp; trích vector
            </button>
            <button
              type="button"
              onClick={() => alert('TODO: tải ảnh lên')}
              className="inline-flex h-10 flex-1 items-center justify-center gap-1.5 rounded-xl border border-slate-200 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              <Upload className="size-4" /> Tải ảnh lên
            </button>
          </div>
        </>
      )}
    </aside>
  )
}