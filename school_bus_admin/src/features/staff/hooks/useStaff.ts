import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { staffService } from '../services/staffService'
import type { StaffFormPayload, StaffMember } from '../types'

export function useStaff() {
  const queryClient = useQueryClient()

  const staffQuery = useQuery({
    queryKey: ['staff-list'],
    queryFn: staffService.getAllStaff,
  })

  const busesQuery = useQuery({
    queryKey: ['fleet-buses'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('buses')
        .select('bus_id, bus_code, license_plate')
        .eq('status', 'ACTIVE')
        .order('bus_code')
      if (error) throw error
      return data
    },
  })

  const routesQuery = useQuery({
    queryKey: ['fleet-routes'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('routes')
        .select('route_id, route_code, route_name')
        .eq('status', 'ACTIVE')
        .order('route_code')
      if (error) throw error
      return data
    },
  })

  const createMutation = useMutation({
    mutationFn: (payload: StaffFormPayload) => staffService.createStaff(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['staff-list'] })
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ staff, payload }: { staff: StaffMember; payload: Partial<StaffFormPayload> }) =>
      staffService.updateStaff(staff, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['staff-list'] })
    },
  })

 const reassignMutation = useMutation({
    mutationFn: ({
      staff,
      busId,
      routeId,
      partnerId,
    }: {
      staff: StaffMember
      busId: string
      routeId: string
      partnerId: string
    }) => staffService.reassignTrip(staff, busId, routeId, partnerId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['staff-list'] })
    },
  })

  return {
    staffQuery,
    busesQuery,
    routesQuery,
    createMutation,
    updateMutation,
    reassignMutation,
  }
}