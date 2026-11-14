import { useState } from 'react'
import { useChildRequests, useStudents } from './hooks/useStudents'
import { StudentsTable } from './components/StudentsTable'
import { FaceRegisterPanel } from './components/FaceRegisterPanel'
import { ChildRequestsPanel } from './components/ChildRequestsPanel'

type Tab = 'LIST' | 'REQUESTS'

export function StudentsPage() {
  const { data = [], isLoading, error } = useStudents()
  const { data: requests = [] } = useChildRequests()
  const [tab, setTab] = useState<Tab>('LIST')
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const selected = data.find((s) => s.id === selectedId) ?? null
  const registered = data.filter((s) => s.faceStatus === 'REGISTERED').length

  const tabCls = (t: Tab) =>
    `h-9 rounded-xl px-4 text-sm font-semibold ${
      tab === t ? 'bg-[#2563EB] text-white' : 'bg-white text-slate-600 hover:bg-slate-50'
    }`

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-[#0F172A]">Học sinh &amp; khuôn mặt</h1>
        <p className="text-sm text-[#64748B]">
          {data.length} học sinh · {registered} đã đăng ký khuôn mặt
        </p>
      </div>

      <div className="flex gap-2">
        <button type="button" className={tabCls('LIST')} onClick={() => setTab('LIST')}>
          Danh sách học sinh
        </button>
        <button type="button" className={tabCls('REQUESTS')} onClick={() => setTab('REQUESTS')}>
          Yêu cầu chờ duyệt
          {requests.length > 0 && (
            <span className="ml-2 rounded-full bg-amber-400 px-2 py-0.5 text-xs font-bold text-white">
              {requests.length}
            </span>
          )}
        </button>
      </div>

      {error && (
        <div className="rounded-xl bg-rose-50 p-3 text-sm text-rose-600">
          Không tải được dữ liệu: {(error as Error).message}
        </div>
      )}

      {tab === 'LIST' ? (
        <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_340px]">
          <StudentsTable
            rows={data}
            isLoading={isLoading}
            selectedId={selectedId}
            onSelect={(s) => setSelectedId(s.id)}
          />
          <FaceRegisterPanel student={selected} />
        </div>
      ) : (
        <ChildRequestsPanel students={data} />
      )}
    </div>
  )
}