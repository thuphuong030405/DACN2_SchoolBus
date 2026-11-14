import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { studentService } from '../services/studentService'

export function useStudents() {
  return useQuery({
    queryKey: ['students'],
    queryFn: studentService.getStudents,
    refetchInterval: 30_000,
    refetchOnWindowFocus: true,
  })
}

export function useChildRequests() {
  return useQuery({
    queryKey: ['child-requests'],
    queryFn: studentService.getChildRequests,
    refetchInterval: 30_000, // phụ huynh gửi xong, tối đa 30 giây là thấy
    refetchOnWindowFocus: true,
  })
}

export function useReviewRequest() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: studentService.reviewRequest,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['child-requests'] })
      qc.invalidateQueries({ queryKey: ['students'] })
    },
  })
}