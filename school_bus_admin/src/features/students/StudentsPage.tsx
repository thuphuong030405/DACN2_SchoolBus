import { useState } from 'react'
import { useStudents } from './hooks/useStudents'
import { StudentsTable } from './components/StudentsTable'
import { FaceRegisterPanel } from './components/FaceRegisterPanel'

export function StudentsPage() {
  const { data = [], isLoading, error } = useStudents()
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const selected = data.find((s) => s.id === selectedId) ?? null
  const registered = data.filter((s) => s.faceStatus === 'REGISTERED').length

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Học sinh &amp; khuôn mặt</h1>
        <p className="text-sm text-[#64748B]">
          {data.length} học sinh · {registered} đã đăng ký khuôn mặt
        </p>
      </div>

      {error && (
        <div className="rounded-xl bg-rose-50 p-3 text-sm text-rose-600">
          Không tải được dữ liệu: {(error as Error).message}
        </div>
      )}

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_340px]">
        <StudentsTable
          rows={data}
          isLoading={isLoading}
          selectedId={selectedId}
          onSelect={(s) => setSelectedId(s.id)}
        />
        <FaceRegisterPanel student={selected} />
      </div>
    </div>
  )
}