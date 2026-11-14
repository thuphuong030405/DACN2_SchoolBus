import { useQuery } from '@tanstack/react-query'
import { studentService } from '../services/studentService'

export function useStudents() {
  return useQuery({
    queryKey: ['students'],
    queryFn: studentService.getStudents,
  })
}