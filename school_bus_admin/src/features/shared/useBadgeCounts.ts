import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

/** Số đơn nghỉ chờ duyệt và cảnh báo đang mở, hiển thị trên thanh bên. */
export function useBadgeCounts() {
  return useQuery({
    queryKey: ['badge-counts'],
    refetchInterval: 30_000,
    queryFn: async () => {
      const [absences, alerts] = await Promise.all([
        supabase.from('absences').select('absence_id', { count: 'exact', head: true }).eq('status', 'PENDING'),
        supabase.from('alerts').select('alert_id', { count: 'exact', head: true }).in('status', ['OPEN', 'PROCESSING']),
      ])
      return { absences: absences.count ?? 0, alerts: alerts.count ?? 0 }
    },
  })
}
