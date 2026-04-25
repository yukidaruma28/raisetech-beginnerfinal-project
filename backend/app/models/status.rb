class Status < ApplicationRecord
  HEX_COLOR_REGEX = /\A#[0-9A-Fa-f]{6}\z/

  validates :name,
            presence: true,
            length: { maximum: 100 }
  validates :color,
            presence: true,
            format: { with: HEX_COLOR_REGEX, message: "must be a hex color like #1A2B3C" }
  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
