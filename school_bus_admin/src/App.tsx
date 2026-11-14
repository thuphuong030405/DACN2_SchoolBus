import { Navigate, Route, Routes } from 'react-router-dom'
import { AppShell } from '@/components/layout/AppShell'
import { ChangePasswordPage } from '@/features/auth/ChangePasswordPage'
import { LoginPage } from '@/features/auth/LoginPage'
import { RequireStaff } from '@/features/auth/RequireStaff'
import { FleetPage } from '@/features/fleet/FleetPage'
import { PagePlaceholder } from '@/features/shared/PagePlaceholder'
import { OverviewPage } from '@/features/overview/OverviewPage'
import { RoutesPage } from '@/features/routes/RoutesPage'
import { StaffPage } from '@/features/staff/StaffPage'
import { AbsencesPage } from '@/features/absences/AbsencesPage'
import { AlertsPage } from '@/features/alerts/AlertsPage'
import { AttendancePage } from '@/features/attendance/AttendancePage'
import { StudentsPage } from '@/features/students/StudentsPage'

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route element={<RequireStaff />}>
        <Route element={<AppShell />}>
          <Route index element={<OverviewPage />} />
          <Route path="monitor" element={<PagePlaceholder title="Giám sát đội xe" />} />
          <Route path="students" element={<StudentsPage />} />
          <Route path="staff" element={<StaffPage />} />
          <Route path="fleet" element={<FleetPage />} />
          <Route path="routes" element={<RoutesPage />} />
          <Route path="attendance" element={<AttendancePage />} />
          <Route path="absences" element={<AbsencesPage/>} />
          <Route path="alerts" element={<AlertsPage/>} />
          <Route path="account" element={<ChangePasswordPage />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
