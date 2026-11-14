export function PagePlaceholder({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="grid min-h-64 place-items-center rounded-3xl bg-white p-10 text-center shadow-sm">
      <div>
        <h2 className="text-lg font-bold">{title}</h2>
        <p className="mt-1 text-sm text-muted-ink">{hint ?? 'Màn hình này sẽ được làm theo thiết kế Figma.'}</p>
      </div>
    </div>
  )
}
