class Priority < ApplicationRecord
  HEX_COLOR_REGEX = /\A#[0-9A-Fa-f]{6}\z/

  # priorities → inquiries は 1 対多。
  # 3 段階に簡素化し inquiries.priority_id を NOT NULL 化したので、
  # 優先度削除時は紐づく inquiries があればエラーで止める（status と同じ運用方針）。
  has_many :inquiries, dependent: :restrict_with_error

  validates :name,
            presence: true,
            length: { maximum: 100 }
  # 3 段階運用（1=高, 2=中, 3=低）。DB の CHECK 制約は 0..4 と広めに残してあるが、
  # アプリ層では 1..3 に絞ってドメインを明確にする。
  validates :level,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 3 },
            uniqueness: true
  validates :color,
            presence: true,
            format: { with: HEX_COLOR_REGEX, message: "must be a hex color like #1A2B3C" }
  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
