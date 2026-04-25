export interface Priority {
  id: number
  name: string
  // Linear 準拠: 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low
  level: number
  color: string
  position: number
  createdAt?: string
  updatedAt?: string
}
