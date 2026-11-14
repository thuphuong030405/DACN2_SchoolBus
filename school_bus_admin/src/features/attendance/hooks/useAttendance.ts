import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { attendanceService } from '../services/attendanceService'
import type { TripOption } from '../types'

export function useAttendance(selectedTrip: TripOption | null) {
  const queryClient = useQueryClient()

  const tripsQuery = useQuery({
    queryKey: ['attendance-trips'],
    queryFn: attendanceService.getTrips,
  })

  const tripAttendanceQuery = useQuery({
    queryKey: ['trip-attendance', selectedTrip?.trip_id],
    enabled: !!selectedTrip,
    queryFn: () => attendanceService.getTripAttendance(selectedTrip!),
  })

  const overviewQuery = useQuery({
    queryKey: ['attendance-overview', tripsQuery.data?.map((t) => t.trip_id)],
    enabled: !!tripsQuery.data,
    queryFn: () => attendanceService.getDailyOverview(tripsQuery.data ?? []),
  })

  const manualCheckInMutation = useMutation({
    mutationFn: ({
      tripId,
      studentId,
      pickupStopId,
    }: {
      tripId: string
      studentId: string
      pickupStopId: string | null
    }) => attendanceService.manualCheckIn(tripId, studentId, pickupStopId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trip-attendance'] })
      queryClient.invalidateQueries({ queryKey: ['attendance-overview'] })
    },
  })

  const completeTripMutation = useMutation({
    mutationFn: (tripId: string) => attendanceService.completeTrip(tripId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['attendance-trips'] })
    },
  })

  return {
    tripsQuery,
    tripAttendanceQuery,
    overviewQuery,
    manualCheckInMutation,
    completeTripMutation,
  }
}