class Inquiry < ApplicationRecord
  belongs_to :status
  # priority は必須（3 段階で必ず割当、デフォルトは「低」）。
  # status と同じく association 側に required を任せ、独立した validates は書かない。
  belongs_to :priority

  validates :title,
            presence: true,
            length: { maximum: 255 }
  # status の presence は `belongs_to :status` が Rails 5+ で自動的に required にする
  # ため、status_id を独立にバリデーションすると build(:inquiry) 時に status_id が
  # まだ確定していないタイミングで失敗してしまう。association 側に任せる。
  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # status 列内で position 昇順、同 position は id 昇順で安定化する。
  scope :ordered, -> { order(:status_id, :position, :id) }
end
