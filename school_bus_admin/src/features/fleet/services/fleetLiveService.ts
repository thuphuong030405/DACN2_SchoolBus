import { supabase } from '@/lib/supabase'
import type { FleetLiveItem } from '../types/fleet-live.types'

export async function getFleetLive(): Promise<FleetLiveItem[]> {
  const { data, error } = await supabase
    .from('vw_fleet_live')
    .select('*')

  if (error) {
    throw error
  }

  return (data ?? []) as FleetLiveItem[]
}