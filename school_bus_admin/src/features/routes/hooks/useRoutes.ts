
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react'

import { routesService, getLocalDate } from '../services/routesService'

import type {
  BusWithTrip,
  GpsLocation,
  RouteSummary,
  Trip,
} from '../types'

export function useRoutes() {
  const [buses, setBuses] = useState<BusWithTrip[]>([])
  const [routes, setRoutes] = useState<RouteSummary[]>([])
  const [trips, setTrips] = useState<Trip[]>([])
  const [gpsLocations, setGpsLocations] = useState<GpsLocation[]>([])

  const [search, setSearch] = useState('')
  const [selectedRoute, setSelectedRoute] = useState('ALL')

  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async (refresh = false) => {
    try {
      if (refresh) {
        setRefreshing(true)
      } else {
        setLoading(true)
      }

      setError(null)

      const today = getLocalDate()

      // Lấy danh sách xe và tuyến độc lập với dữ liệu chuyến.
      const [busData, routeData, tripResult] = await Promise.all([
        routesService.getBuses(),
        routesService.getRoutes(),
        routesService.getTrips(today).then(
          (data) => ({ data, error: null as unknown }),
          (error: unknown) => ({ data: [] as Trip[], error }),
        ),
      ])

      // GPS có lỗi không làm mất danh sách phương tiện.
      const gpsData = await routesService
        .getGpsLocations(today)
        .catch((gpsError: unknown) => {
          console.error('Không tải được GPS:', gpsError)
          return [] as GpsLocation[]
        })

      if (tripResult.error) {
        console.error('Không tải được chuyến xe:', tripResult.error)
      }

      const tripData = tripResult.data

      // BẮT BUỘC giữ toàn bộ xe lấy được từ bảng buses.
      const mappedBuses = routesService.buildBuses(
        busData,
        tripData,
      )

      const mappedRoutes = routesService.buildRoutes(
        routeData,
        mappedBuses,
      )

      setBuses(mappedBuses)
      setRoutes(mappedRoutes)
      setTrips(tripData)
      setGpsLocations(gpsData)

      if (tripResult.error) {
        setError('Đã tải danh sách xe và tuyến, nhưng chưa tải được chuyến xe hôm nay.')
      }
    } catch (err: unknown) {
      console.error('Routes loading error:', err)

      setError(
        err instanceof Error
          ? err.message
          : 'Không thể tải dữ liệu từ Supabase.',
      )
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  // Tìm kiếm nhưng không tự động loại xe chưa phân công.
  const filteredBuses = useMemo(() => {
    const keyword = search.trim().toLocaleLowerCase('vi')

    return buses.filter((bus) => {
      const matchesSearch =
        !keyword ||
        [
          bus.bus_code,
          bus.license_plate,
          bus.vehicle_model,
          bus.driverName,
          bus.teacherName,
          bus.routeName,
        ].some((value) =>
          String(value ?? '')
            .toLocaleLowerCase('vi')
            .includes(keyword),
        )

      const matchesRoute =
        selectedRoute === 'ALL' ||
        bus.currentTrip?.route_id === selectedRoute

      return matchesSearch && matchesRoute
    })
  }, [buses, search, selectedRoute])

  const activeBuses = useMemo(
    () => buses.filter((bus) => bus.status === 'ACTIVE').length,
    [buses],
  )

  const runningTrips = useMemo(
    () => trips.filter((trip) => trip.status === 'IN_PROGRESS').length,
    [trips],
  )

  const maintenanceBuses = useMemo(
    () => buses.filter((bus) => bus.status === 'MAINTENANCE').length,
    [buses],
  )

  const getLatestGps = useCallback(
    (tripId: string) =>
      gpsLocations.find((gps) => gps.trip_id === tripId) ?? null,
    [gpsLocations],
  )

  return {
    buses,
    routes,
    trips,
    gpsLocations,
    filteredBuses,

    search,
    setSearch,

    selectedRoute,
    setSelectedRoute,

    activeBuses,
    runningTrips,
    maintenanceBuses,

    loading,
    refreshing,
    error,

    reload: () => loadData(true),
    getLatestGps,
  }
}
