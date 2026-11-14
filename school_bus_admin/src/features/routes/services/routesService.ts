
import { supabase } from '@/lib/supabase'

import type {
  Bus,
  BusWithTrip,
  GpsLocation,
  RouteSummary,
  Trip,
} from '../types'

export function getLocalDate(): string {
  const now = new Date()

  return [
    now.getFullYear(),
    String(now.getMonth() + 1).padStart(2, '0'),
    String(now.getDate()).padStart(2, '0'),
  ].join('-')
}

function sortGps<T extends { recorded_at: string }>(
  items: T[],
): T[] {
  return [...items].sort(
    (a, b) =>
      new Date(b.recorded_at).getTime() -
      new Date(a.recorded_at).getTime(),
  )
}

export type CreateBusData = {
  bus_code: string
  license_plate: string
  capacity: number
  vehicle_model: string | null
  status: Bus['status']
}

export const routesService = {
    async createBus(payload: CreateBusData): Promise<Bus> {
    const { data, error } = await supabase
      .from('buses')
      .insert({
        bus_code: payload.bus_code.trim(),
        license_plate: payload.license_plate.trim(),
        capacity: payload.capacity,
        vehicle_model: payload.vehicle_model?.trim() || null,
        status: payload.status,
      })
      .select('*')
      .single()

    if (error) {
      console.error('Lỗi thêm xe:', error)
      throw error
    }

    return data as Bus
  },
  // LẤY TẤT CẢ XE TRONG BẢNG BUSES
  async getBuses(): Promise<Bus[]> {
    const { data, error } = await supabase
      .from('buses')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Lỗi lấy danh sách xe:', error)
      throw error
    }

    return (data ?? []) as Bus[]
  },

  // LẤY TẤT CẢ TUYẾN VÀ ĐIỂM DỪNG
  async getRoutes(): Promise<RouteSummary[]> {
    const { data, error } = await supabase
      .from('routes')
      .select(`
        *,
        route_stops (*)
      `)
      .order('route_code', { ascending: true })

    if (error) {
      console.error('Lỗi lấy tuyến đường:', error)
      throw error
    }

    return (data ?? []).map((item: any) => {
      const stops = [...(item.route_stops ?? [])].sort(
        (a, b) => a.stop_order - b.stop_order,
      )

      return {
        ...item,
        route_stops: stops,
        stops,
        busCount: 0,
        activeBusCount: 0,
      }
    }) as RouteSummary[]
  },

  // LẤY CÁC CHUYẾN TRONG NGÀY
  async getTrips(date: string = getLocalDate()): Promise<Trip[]> {
    const { data, error } = await supabase
      .from('trips')
      .select(`
        *,
        buses (*),
        routes (
          *,
          route_stops (*)
        ),
        drivers (
          *,
          users (*)
        ),
        teachers (
          *,
          users (*)
        ),
        gps_locations (*)
      `)
      .eq('trip_date', date)
      .order('start_at', { ascending: true })

    if (error) {
      console.error('Lỗi lấy chuyến xe:', error)
      throw error
    }

    return (data ?? []).map((trip: any) => {
      const stops = [...(trip.routes?.route_stops ?? [])].sort(
        (a, b) => a.stop_order - b.stop_order,
      )

      return {
        ...trip,
        routes: trip.routes
          ? {
              ...trip.routes,
              route_stops: stops,
            }
          : null,
        gps_locations: sortGps(trip.gps_locations ?? []),
      }
    }) as Trip[]
  },

  // LẤY GPS CỦA CÁC CHUYẾN TRONG NGÀY
  async getGpsLocations(
    date: string = getLocalDate(),
  ): Promise<GpsLocation[]> {
    const { data, error } = await supabase
      .from('gps_locations')
      .select(`
        *,
        trips!inner (
          trip_id,
          trip_date
        )
      `)
      .eq('trips.trip_date', date)
      .order('recorded_at', { ascending: false })
      .limit(200)

    if (error) {
      console.error('Lỗi lấy GPS:', error)
      throw error
    }

    return (data ?? []) as unknown as GpsLocation[]
  },

  // GHÉP TẤT CẢ XE VỚI CHUYẾN NẾU CÓ
  buildBuses(
    buses: Bus[],
    trips: Trip[],
  ): BusWithTrip[] {
    return buses.map((bus) => {
      const busTrips = trips
        .filter((trip) => trip.bus_id === bus.bus_id)
        .sort((a, b) => {
          const priority: Record<string, number> = {
            IN_PROGRESS: 1,
            SCHEDULED: 2,
            COMPLETED: 3,
            CANCELLED: 4,
          }

          return (
            (priority[a.status] ?? 5) -
            (priority[b.status] ?? 5)
          )
        })

      const currentTrip = busTrips[0] ?? null

      return {
        ...bus,
        currentTrip,

        driverName:
          currentTrip?.drivers?.users?.full_name ??
          'Chưa phân công',

        teacherName:
          currentTrip?.teachers?.users?.full_name ??
          'Chưa phân công',

        routeName:
          currentTrip?.routes?.route_name ??
          'Chưa có tuyến',

        latestGps:
          currentTrip?.gps_locations?.[0] ?? null,
      }
    })
  },

  // THỐNG KÊ XE THEO TUYẾN
  buildRoutes(
    routes: RouteSummary[],
    buses: BusWithTrip[],
  ): RouteSummary[] {
    return routes.map((route) => {
      const routeBuses = buses.filter(
        (bus) => bus.currentTrip?.route_id === route.route_id,
      )

      return {
        ...route,
        busCount: routeBuses.length,
        activeBusCount: routeBuses.filter(
          (bus) => bus.currentTrip?.status === 'IN_PROGRESS',
        ).length,
      }
    })
  },
}

