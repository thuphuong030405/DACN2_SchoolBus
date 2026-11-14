import { useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  Bus,
  Check,
  Eye,
  EyeOff,
  Lock,
  Mail,
  MapPin,
  MonitorSmartphone,
  ScanFace,
  ShieldCheck,
  TriangleAlert,
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuth } from './useAuth'

const schema = z.object({
  email: z.string().trim().email('Email không hợp lệ'),
  password: z.string().min(6, 'Mật khẩu tối thiểu 6 ký tự'),
})
type FormValues = z.infer<typeof schema>

const FEATURES = [
  {
    icon: MapPin,
    title: 'Giám sát đội xe trực tiếp',
    sub: 'Vị trí, tốc độ và sĩ số từng chuyến',
  },
  {
    icon: ScanFace,
    title: 'Điểm danh bằng nhận diện khuôn mặt',
    sub: 'Chạy trên thiết bị, dữ liệu được mã hóa',
  },
  {
    icon: TriangleAlert,
    title: 'Cảnh báo bỏ quên trẻ tức thì',
    sub: 'Gửi đến nhà trường và phụ huynh',
  },
]

export function LoginPage() {
  const { session, profile, error, signIn } = useAuth()
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [infoMsg, setInfoMsg] = useState<string | null>(null)
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(true)

  const {
    register,
    handleSubmit,
    getValues,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      email: localStorage.getItem('remembered_email') ?? '',
      password: '',
    },
  })

  if (session && profile) return <Navigate to="/" replace />

  const onSubmit = async (v: FormValues) => {
    setSubmitError(null)
    setInfoMsg(null)
    try {
      if (rememberMe) {
        localStorage.setItem('remembered_email', v.email.trim())
      } else {
        localStorage.removeItem('remembered_email')
      }
      await signIn(v.email.trim(), v.password)
    } catch (e) {
      setSubmitError(e instanceof Error ? e.message : 'Không đăng nhập được.')
    }
  }

  const handleForgotPassword = async () => {
    setSubmitError(null)
    setInfoMsg(null)
    const email = getValues('email')?.trim()
    if (!email) {
      setSubmitError('Vui lòng nhập email vào ô phía trên trước khi bấm Quên mật khẩu.')
      return
    }
    const { error: resetErr } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/account`,
    })
    if (resetErr) {
      setSubmitError(resetErr.message)
    } else {
      setInfoMsg(`Đã gửi liên kết đặt lại mật khẩu tới ${email}. Vui lòng kiểm tra hộp thư.`)
    }
  }

  return (
    <div className="flex min-h-screen w-full bg-[#F3F6FC] text-[#0F172A]">
      {/* CỘT TRÁI: Nền xanh thương hiệu + Giới thiệu + Minh họa xe buýt */}
      <aside className="relative hidden flex-1 flex-col justify-between overflow-hidden bg-[#1D51D8] p-12 text-white lg:flex xl:p-16">
        {/* Các hình tròn trang trí nền (Decor blobs) */}
        <div className="pointer-events-none absolute -right-24 -top-24 size-[420px] rounded-full bg-[#163EB0]/65" />
        <div className="pointer-events-none absolute -left-16 bottom-20 size-40 rounded-full bg-[#2E66F2]/70" />

        <div className="relative z-10 flex flex-col gap-10">
          {/* Logo */}
          <div className="flex items-center gap-3.5">
            <span className="grid size-11 place-items-center rounded-2xl bg-[#FACC15] text-[#0F172A] shadow-sm">
              <Bus className="size-6 stroke-[2.2]" />
            </span>
            <b className="text-xl font-bold tracking-tight">Bus An Toàn</b>
          </div>

          {/* Tiêu đề & Mô tả */}
          <div className="mt-2 max-w-md space-y-4">
            <h1 className="text-2xl font-bold leading-[1.2] tracking-tight xl:text-[36px]">
              Quản lý đưa đón học sinh an toàn và minh bạch
            </h1>
            <p className="text-[15px] leading-relaxed text-white/80">
              Giám sát xe theo thời gian thực, điểm danh bằng AI và cảnh báo ngay khi còn sót trẻ trên xe.
            </p>
          </div>

          {/* 3 Tính năng nổi bật */}
          <ul className="mt-2 flex flex-col gap-5">
            {FEATURES.map(({ icon: Icon, title, sub }) => (
              <li key={title} className="flex items-center gap-4">
                <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-white/10 text-[#FACC15] backdrop-blur-xs">
                  <Icon className="size-5" />
                </span>
                <div>
                  <b className="block text-[15px] font-semibold">{title}</b>
                  <span className="text-xs text-white/75">{sub}</span>
                </div>
              </li>
            ))}
          </ul>
        </div>

        {/* Hình minh họa Xe buýt + Đám mây + Mặt trời góc dưới trái */}
        <div className="relative z-10 mt-8 pt-4">
          <svg
            viewBox="0 0 340 155"
            className="w-72 select-none xl:w-80"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            {/* Mặt trời vàng */}
            <circle cx="268" cy="36" r="22" fill="#FACC15" />

            {/* Đám mây mờ */}
            <ellipse cx="105" cy="36" rx="28" ry="12" fill="white" fillOpacity="0.88" />
            <ellipse cx="132" cy="40" rx="24" ry="10" fill="white" fillOpacity="0.65" />

            {/* Mặt đường xanh đậm */}
            <rect x="12" y="132" width="276" height="12" rx="6" fill="#153BA3" />

            {/* Thân xe buýt vàng */}
            <rect x="48" y="64" width="194" height="62" rx="18" fill="#FACC15" />

            {/* Cửa sổ xe buýt */}
            <rect x="64" y="76" width="32" height="22" rx="6" fill="#DBEAFE" />
            <rect x="104" y="76" width="34" height="22" rx="6" fill="#DBEAFE" />
            <rect x="146" y="76" width="34" height="22" rx="6" fill="#DBEAFE" />
            <rect x="188" y="76" width="36" height="22" rx="6" fill="#DBEAFE" />

            {/* Đường kẻ sọc trang trí giữa thân xe */}
            <rect x="48" y="106" width="194" height="5" fill="#1E293B" />

            {/* Bánh xe trái */}
            <circle cx="92" cy="128" r="16" fill="#0F172A" />
            <circle cx="92" cy="128" r="6" fill="#E2E8F0" />

            {/* Bánh xe phải */}
            <circle cx="196" cy="128" r="16" fill="#0F172A" />
            <circle cx="196" cy="128" r="6" fill="#E2E8F0" />
          </svg>
        </div>
      </aside>

      {/* CỘT PHẢI: Form Đăng nhập */}
      <main className="flex flex-1 flex-col items-center justify-center p-6 sm:p-10">
        <div className="w-full max-w-[440px]">
          <form
            onSubmit={handleSubmit(onSubmit)}
            className="flex flex-col gap-5 rounded-[28px] bg-white p-8 shadow-[0_10px_40px_-15px_rgba(15,23,42,0.08)] sm:p-10"
            noValidate
          >
            {/* Header Form */}
            <div className="space-y-1">
              <h2 className="text-2xl font-bold tracking-tight text-[#0F172A]">Đăng nhập Ban giám hiệu</h2>
              <p className="text-sm text-[#64748B]">Chào mừng trở lại, vui lòng nhập thông tin của bạn</p>
            </div>

            {/* Input Email */}
            <div className="flex flex-col gap-2">
              <Label htmlFor="email" className="text-xs font-semibold text-[#1E293B]">
                Email
              </Label>
              <div className="relative">
                <Mail className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-[#64748B]" />
                <Input
                  id="email"
                  type="email"
                  placeholder="bgh@truong.edu.vn"
                  autoComplete="username"
                  className="h-11 rounded-xl border-[#E2E8F0] pl-10 text-sm focus-visible:ring-[#1D51D8]"
                  {...register('email')}
                />
              </div>
              {errors.email && <p className="text-xs text-red-600">{errors.email.message}</p>}
            </div>

            {/* Input Mật khẩu */}
            <div className="flex flex-col gap-2">
              <Label htmlFor="password" className="text-xs font-semibold text-[#1E293B]">
                Mật khẩu
              </Label>
              <div className="relative">
                <Lock className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-[#64748B]" />
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  autoComplete="current-password"
                  className="h-11 rounded-xl border-[#E2E8F0] pl-10 pr-10 text-sm focus-visible:ring-[#1D51D8]"
                  {...register('password')}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((prev) => !prev)}
                  aria-label={showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#64748B] hover:text-[#0F172A]"
                >
                  {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
              {errors.password && <p className="text-xs text-red-600">{errors.password.message}</p>}
            </div>

            {/* Ghi nhớ đăng nhập & Quên mật khẩu */}
            <div className="flex items-center justify-between text-xs">
              <button
                type="button"
                onClick={() => setRememberMe((v) => !v)}
                className="flex items-center gap-2 font-medium text-[#334155] select-none"
              >
                <span
                  className={`grid size-4 place-items-center rounded transition-colors ${
                    rememberMe ? 'bg-[#1D51D8] text-white' : 'border border-slate-300 bg-white'
                  }`}
                >
                  {rememberMe && <Check className="size-3 stroke-[3]" />}
                </span>
                Ghi nhớ đăng nhập
              </button>

              <button
                type="button"
                onClick={() => void handleForgotPassword()}
                className="font-semibold text-[#1D51D8] hover:underline"
              >
                Quên mật khẩu?
              </button>
            </div>

            {/* Thông báo lỗi / thành công */}
            {(submitError || error) && (
              <p role="alert" className="rounded-xl bg-red-50 p-3 text-xs font-medium text-red-700">
                {submitError ?? error}
              </p>
            )}
            {infoMsg && (
              <p role="status" className="rounded-xl bg-emerald-50 p-3 text-xs font-medium text-emerald-800">
                {infoMsg}
              </p>
            )}

            {/* Nút Đăng nhập */}
            <Button
              type="submit"
              disabled={isSubmitting}
              className="h-11 rounded-xl bg-[#1D51D8] text-sm font-semibold text-white shadow-sm hover:bg-[#163EB0]"
            >
              {isSubmitting ? 'Đang đăng nhập...' : 'Đăng nhập'}
            </Button>

            {/* Hộp thông báo bảo mật bên trong card */}
            <div className="flex items-start gap-3 rounded-xl bg-[#EEF4FF] p-3.5 text-xs leading-relaxed text-[#1E3A8A]">
              <ShieldCheck className="mt-0.5 size-4 shrink-0 text-[#1D51D8]" />
              <span>
                Chỉ dành cho Ban giám hiệu và quản trị viên. Mọi lần đăng nhập đều được ghi nhật ký.
              </span>
            </div>
          </form>

          {/* Chú thích ngoài card dưới cùng */}
          <p className="mt-5 flex items-center justify-center gap-2 text-center text-xs text-[#64748B]">
            <MonitorSmartphone className="size-4 shrink-0" />
            <span>Phụ huynh, giáo viên và tài xế vui lòng dùng ứng dụng di động.</span>
          </p>
        </div>
      </main>
    </div>
  )
}