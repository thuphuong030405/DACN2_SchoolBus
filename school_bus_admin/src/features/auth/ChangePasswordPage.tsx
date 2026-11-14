import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Check, Eye, EyeOff, Laptop, LogOut, ShieldCheck } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuth } from './useAuth'

const schema = z
  .object({
    current: z.string().min(1, 'Nhập mật khẩu hiện tại'),
    next: z
      .string()
      .min(8, 'Tối thiểu 8 ký tự')
      .regex(/[A-Za-z]/, 'Cần có chữ cái')
      .regex(/\d/, 'Cần có chữ số'),
    confirm: z.string(),
  })
  .refine((v) => v.next === v.confirm, { path: ['confirm'], message: 'Mật khẩu nhập lại không khớp' })

type FormValues = z.infer<typeof schema>

const SECURITY_TIPS = [
  'Dùng một mật khẩu riêng cho hệ thống này, không dùng lại ở nơi khác.',
  'Không chia sẻ tài khoản Ban giám hiệu cho người khác.',
  'Đăng xuất khi dùng máy tính chung.',
  'Báo ngay cho quản trị viên nếu thấy phiên đăng nhập lạ.',
]

export function ChangePasswordPage() {
  const { profile } = useAuth()
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null)
  const [showPass, setShowPass] = useState({ current: false, next: false, confirm: false })

  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  const nextVal = watch('next') || ''
  const hasMinLen = nextVal.length >= 8
  const hasAlphaNum = /[A-Za-z]/.test(nextVal) && /\d/.test(nextVal)
  const hasSpecial = /[^A-Za-z0-9]/.test(nextVal)
  const strengthScore = [hasMinLen, hasAlphaNum, hasSpecial, nextVal.length >= 12].filter(Boolean).length

  const onSubmit = async (v: FormValues) => {
    setMessage(null)
    if (!profile) return

    const check = await supabase.auth.signInWithPassword({ email: profile.email, password: v.current })
    if (check.error) {
      setMessage({ ok: false, text: 'Mật khẩu hiện tại không đúng.' })
      return
    }
    const upd = await supabase.auth.updateUser({ password: v.next })
    if (upd.error) {
      setMessage({ ok: false, text: upd.error.message })
      return
    }
    await supabase.auth.signOut({ scope: 'others' })
    reset()
    setMessage({ ok: true, text: 'Đã đổi mật khẩu và đăng xuất các thiết bị khác.' })
  }

  const handleSignOutOthers = async () => {
    const { error } = await supabase.auth.signOut({ scope: 'others' })
    if (error) {
      setMessage({ ok: false, text: error.message })
    } else {
      setMessage({ ok: true, text: 'Đã gửi lệnh đăng xuất khỏi tất cả thiết bị khác.' })
    }
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
      {/* Cột trái: Form đổi mật khẩu */}
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="flex flex-col gap-5 rounded-3xl bg-white p-7 shadow-sm lg:col-span-7"
        noValidate
      >
        <h2 className="text-lg font-bold">Đổi mật khẩu</h2>

        {(
          [
            ['current', 'Mật khẩu hiện tại', 'current-password'],
            ['next', 'Mật khẩu mới', 'new-password'],
            ['confirm', 'Nhập lại mật khẩu mới', 'new-password'],
          ] as const
        ).map(([name, label, auto]) => (
          <div key={name} className="flex flex-col gap-2">
            <Label htmlFor={name}>{label}</Label>
            <div className="relative">
              <Input
                id={name}
                type={showPass[name] ? 'text' : 'password'}
                autoComplete={auto}
                className="pr-10"
                {...register(name)}
              />
              <button
                type="button"
                onClick={() => setShowPass((p) => ({ ...p, [name]: !p[name] }))}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-ink hover:text-ink"
              >
                {showPass[name] ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
            {errors[name] && <p className="text-sm text-red-600">{errors[name]?.message}</p>}

            {/* Thanh đo độ mạnh + Checklist ngay dưới ô Mật khẩu mới */}
            {name === 'next' && (
              <div className="mt-1 flex flex-col gap-3">
                <div className="grid grid-cols-4 gap-2">
                  {[1, 2, 3, 4].map((step) => (
                    <div
                      key={step}
                      className={`h-1.5 rounded-full transition-colors ${
                        strengthScore >= step ? 'bg-emerald-500' : 'bg-slate-200'
                      }`}
                    />
                  ))}
                </div>
                <div className="flex flex-col gap-2 rounded-2xl bg-slate-50 p-4 text-sm">
                  {[
                    { ok: hasMinLen, text: 'Tối thiểu 8 ký tự' },
                    { ok: hasAlphaNum, text: 'Cả chữ hoa/thường và chữ số' },
                    { ok: hasSpecial, text: 'Có ký tự đặc biệt (nên có)' },
                  ].map((item) => (
                    <div key={item.text} className="flex items-center gap-2.5">
                      <span
                        className={`grid size-4 place-items-center rounded text-white ${
                          item.ok ? 'bg-blue-600' : 'border border-slate-300 bg-white'
                        }`}
                      >
                        {item.ok && <Check className="size-3" />}
                      </span>
                      <span className={item.ok ? 'font-medium text-ink' : 'text-muted-ink'}>{item.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        ))}

        {message && (
          <p
            role="status"
            className={`rounded-xl p-3 text-sm ${message.ok ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-700'}`}
          >
            {message.text}
          </p>
        )}

        <div className="flex items-center gap-3 pt-1">
          <Button type="submit" disabled={isSubmitting} className="h-11 px-5">
            {isSubmitting ? 'Đang cập nhật...' : 'Cập nhật mật khẩu'}
          </Button>
          <Button type="button" variant="outline" onClick={() => reset()} className="h-11 px-5">
            Hủy
          </Button>
        </div>
      </form>

      {/* Cột phải: Phiên đăng nhập & Gợi ý bảo mật */}
      <div className="flex flex-col gap-6 lg:col-span-5">
        <section className="flex flex-col gap-4 rounded-3xl bg-white p-7 shadow-sm">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold">Phiên đăng nhập</h2>
            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-muted-ink">
              Đang hoạt động
            </span>
          </div>

          <div className="flex items-center justify-between rounded-2xl border border-slate-100 bg-slate-50/70 p-3.5">
            <div className="flex items-center gap-3">
              <span className="grid size-10 place-items-center rounded-xl bg-blue-50 text-blue-600">
                <Laptop className="size-5" />
              </span>
              <div>
                <b className="block text-sm">Trình duyệt hiện tại</b>
                <span className="text-xs text-muted-ink">{profile?.email}</span>
              </div>
            </div>
            <span className="rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700">
              Thiết bị này
            </span>
          </div>

          <Button
            type="button"
            variant="outline"
            onClick={() => void handleSignOutOthers()}
            className="h-11 border-red-200 text-red-600 hover:bg-red-50 hover:text-red-700"
          >
            <LogOut className="mr-2 size-4" />
            Đăng xuất tất cả thiết bị khác
          </Button>
        </section>

        <section className="flex flex-col gap-3 rounded-3xl bg-white p-7 shadow-sm">
          <h2 className="text-lg font-bold">Gợi ý bảo mật</h2>
          <ul className="flex flex-col gap-2.5 text-sm text-muted-ink">
            {SECURITY_TIPS.map((tip) => (
              <li key={tip} className="flex items-start gap-2.5">
                <ShieldCheck className="mt-0.5 size-4 shrink-0 text-blue-600" />
                <span>{tip}</span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  )
}