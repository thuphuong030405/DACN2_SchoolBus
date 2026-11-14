import type { BusLocation } from '../types/fleet.types'
import { supabase } from '@/lib/supabase'

import type {
  BusItem,
  RouteItem,
  RouteStop,
} from '../types/fleet.types'

import { normalizeBusStatus } from '../types/fleet.types'

export async function getBuses(): Promise<BusItem[]> {
  const { data, error } = await supabase
    .from('buses')
    .select('*')
    .order('bus_code')

  if (error) throw error

  return (data ?? []).map((bus) => ({
    ...bus,
    status: normalizeBusStatus(bus.status),
  })) as BusItem[]
}

export async function getRoutes(): Promise<RouteItem[]> {
  const { data, error } = await supabase
    .from('routes')
    .select('*')
    .order('route_code')

  if (error) throw error

  return (data ?? []) as RouteItem[]
}

export async function getRouteStops(
  routeId: string
): Promise<RouteStop[]> {
  const { data, error } = await supabase
    .from('route_stops')
    .select('*')
    .eq('route_id', routeId)
    .eq('is_active', true)
    .order('stop_order')

  if (error) throw error

  return (data ?? []) as RouteStop[]
}

// Lấy vị trí GPS mới nhất của từng xe đang chạy
export async function getFleetLive(): Promise<BusLocation[]> {
  const { data, error } = await supabase
    .from('gps_locations')
    .select(`
      gps_id,
      trip_id,
      latitude,
      longitude,
      speed,
      heading,
      accuracy,
      recorded_at,
      trips!inner (
        trip_id,
        bus_id,
        route_id,
        status,
        buses!inner (
          bus_id,
          bus_code,
          license_plate
        )
      )
    `)
    .eq('trips.status', 'IN_PROGRESS')
    .order('recorded_at', { ascending: false })

  if (error) {
    throw error
  }

  const latestByBus = new Map<string, BusLocation>()

  for (const item of (data ?? []) as any[]) {
    const trip = item.trips
    const bus = trip?.buses

    if (!trip || !bus) continue

    // Vì dữ liệu đã sắp xếp mới nhất trước,
    // chỉ lấy bản ghi đầu tiên của mỗi xe.
    if (latestByBus.has(bus.bus_id)) continue

    latestByBus.set(bus.bus_id, {
      gps_id: item.gps_id,
      trip_id: item.trip_id,
      bus_id: bus.bus_id,
      bus_code: bus.bus_code,
      license_plate: bus.license_plate,
      route_id: trip.route_id,
      trip_status: trip.status,
      latitude: Number(item.latitude),
      longitude: Number(item.longitude),
      speed: item.speed == null ? null : Number(item.speed),
      heading: item.heading == null ? null : Number(item.heading),
      accuracy: item.accuracy == null ? null : Number(item.accuracy),
      recorded_at: item.recorded_at,
    })
  }

  return Array.from(latestByBus.values())
}