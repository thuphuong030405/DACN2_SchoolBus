import type { AbsenceStats as AbsenceStatsType } from '../types'
import './AbsenceStats.css'

interface AbsenceStatsProps {
  stats: AbsenceStatsType
}

export default function AbsenceStats({
  stats,
}: AbsenceStatsProps) {
  const cards = [
    {
      label: 'Chờ duyệt',
      value: stats.pending,
      icon: '⏳',
      color: 'orange',
      description: 'Đơn cần xử lý',
    },
    {
      label: 'Đã duyệt',
      value: stats.approved,
      icon: '✓',
      color: 'green',
      description: 'Đơn đã được duyệt',
    },
    {
      label: 'Đã từ chối',
      value: stats.rejected,
      icon: '×',
      color: 'red',
      description: 'Đơn không được duyệt',
    },
    {
      label: 'Nghỉ hôm nay',
      value: stats.absentToday,
      icon: '▣',
      color: 'blue',
      description: 'Đơn đã duyệt trong ngày',
    },
  ]

  return (
    <div className="leave-stats">
      {cards.map((card) => (
        <div
          className={`leave-stat-card leave-stat-${card.color}`}
          key={card.label}
        >
          <div className="leave-stat-top">
            <span className="leave-stat-label">{card.label}</span>
            <span className="leave-stat-icon">{card.icon}</span>
          </div>

          <div className="leave-stat-value">{card.value}</div>

          <div className="leave-stat-description">
            {card.description}
          </div>
        </div>
      ))}
    </div>
  )
}