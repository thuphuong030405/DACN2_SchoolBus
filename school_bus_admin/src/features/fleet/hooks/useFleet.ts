import { useEffect, useMemo, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'

import { supabase } from '@/lib/supabase'

import {
  getBuses,
  getRoutes,
  getRouteStops,
  getFleetLive,
} from '../services/fleetService'

import type {
  FilterType,
  FleetCounts,
} from '../types/fleet.types'

export function useFleet() {
  const queryClient = useQueryClient()

  const [filter, setFilter] = useState<FilterType>('ALL')
  const [selectedBusId, setSelectedBusId] = useState<string | null>(null)
  const [selectedRouteId, setSelectedRouteId] = useState<string | null>(null)

  // =====================================================
  // 1. DANH SÁCH XE
  // =====================================================

  const buses = useQuery({
    queryKey: ['fleet-buses'],
    queryFn: getBuses,
  })

  // =====================================================
  // 2. DANH SÁCH TUYẾN
  // =====================================================

  const routes = useQuery({
    queryKey: ['fleet-routes'],
    queryFn: getRoutes,
  })

  // =====================================================
  // 3. VỊ TRÍ GPS CỦA XE ĐANG CHẠY
  // =====================================================

  const fleetLive = useQuery({
    queryKey: ['fleet-live'],
    queryFn: getFleetLive,
    refetchInterval: 15000,
    staleTime: 5000,
  })

  // =====================================================
  // 4. TỰ ĐỘNG CHỌN XE ĐẦU TIÊN
  // =====================================================

  useEffect(() => {
    if (!buses.data?.length) {
      setSelectedBusId(null)
      return
    }

    const selectedExists = buses.data.some(
      (bus) => bus.bus_id === selectedBusId
    )

    if (!selectedExists) {
      setSelectedBusId(buses.data[0].bus_id)
    }
  }, [buses.data, selectedBusId])

  // =====================================================
  // 5. TỰ ĐỘNG CHỌN TUYẾN ĐẦU TIÊN
  // =====================================================

  useEffect(() => {
    if (!routes.data?.length) {
      setSelectedRouteId(null)
      return
    }

    const selectedExists = routes.data.some(
      (route) => route.route_id === selectedRouteId
    )

    if (!selectedExists) {
      setSelectedRouteId(routes.data[0].route_id)
    }
  }, [routes.data, selectedRouteId])

  // =====================================================
  // 6. XE ĐANG CHỌN
  // =====================================================

  const selectedBus = useMemo(() => {
    return (
      buses.data?.find(
        (bus) => bus.bus_id === selectedBusId
      ) ?? null
    )
  }, [buses.data, selectedBusId])

  // =====================================================
  // 7. TUYẾN ĐANG CHỌN
  // =====================================================

  const selectedRoute = useMemo(() => {
    return (
      routes.data?.find(
        (route) => route.route_id === selectedRouteId
      ) ?? null
    )
  }, [routes.data, selectedRouteId])

  // =====================================================
  // 8. ĐIỂM DỪNG CỦA TUYẾN ĐANG CHỌN
  // =====================================================

  const stops = useQuery({
    queryKey: ['fleet-stops', selectedRouteId],
    enabled: !!selectedRouteId,
    queryFn: () => getRouteStops(selectedRouteId!),
  })

  // =====================================================
  // 9. LỌC XE THEO TRẠNG THÁI
  // =====================================================

  const filteredBuses = useMemo(() => {
    return (buses.data ?? []).filter((bus) => {
      return filter === 'ALL' || bus.status === filter
    })
  }, [buses.data, filter])

  // =====================================================
  // 10. THỐNG KÊ SỐ LƯỢNG XE
  // =====================================================

  const counts = useMemo<FleetCounts>(() => {
    const list = buses.data ?? []

    return {
      all: list.length,
      active: list.filter(
        (bus) => bus.status === 'ACTIVE'
      ).length,
      warning: list.filter(
        (bus) => bus.status === 'MAINTENANCE'
      ).length,
      inactive: list.filter(
        (bus) => bus.status === 'INACTIVE'
      ).length,
    }
  }, [buses.data])

  // =====================================================
  // 11. SUPABASE REALTIME - THEO DÕI GPS
  // =====================================================

  useEffect(() => {
    const channel = supabase
      .channel('fleet-gps-realtime')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'gps_locations',
        },
        () => {
          queryClient.invalidateQueries({
            queryKey: ['fleet-live'],
          })
        }
      )
      .subscribe()

    return () => {
      void supabase.removeChannel(channel)
    }
  }, [queryClient])

  // =====================================================
  // 12. LÀM MỚI TOÀN BỘ DỮ LIỆU
  // =====================================================

  const refresh = async () => {
    await Promise.all([
      queryClient.invalidateQueries({
        queryKey: ['fleet-buses'],
      }),
      queryClient.invalidateQueries({
        queryKey: ['fleet-routes'],
      }),
      queryClient.invalidateQueries({
        queryKey: ['fleet-stops'],
      }),
      queryClient.invalidateQueries({
        queryKey: ['fleet-live'],
      }),
    ])
  }

  // =====================================================
  // 13. TRẢ DỮ LIỆU CHO FLEET PAGE
  // =====================================================

  return {
    buses,
    routes,
    stops,
    fleetLive,

    filteredBuses,
    selectedBus,
    selectedRoute,

    selectedBusId,
    selectedRouteId,

    filter,
    setFilter,
    setSelectedBusId,
    setSelectedRouteId,

    counts,
    refresh,

    // Dữ liệu GPS đã được chuẩn hóa
    locations: fleetLive.data ?? [],

    // Trạng thái tải dữ liệu
    isLoading:
      buses.isLoading ||
      routes.isLoading,

    isLiveLoading: fleetLive.isLoading,

    // Lỗi truy vấn
    error:
      buses.error ||
      routes.error ||
      fleetLive.error ||
      null,
  }
}