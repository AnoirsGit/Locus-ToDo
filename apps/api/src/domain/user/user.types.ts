export type User = {
  id: string
  email: string
  name: string
  timezone: string
  avatarUrl?: string
  createdAt: string
}

export type UserWithHash = User & { passwordHash: string }

export type UserSettings = {
  userId: string
  notificationOffsetMin: number
  notifyOverdue: boolean
  notifyDailySummary: boolean
  dailySummaryTime: string
}
