class Status < ApplicationRecord
  HEX_COLOR_REGEX = /\A#[0-9A-Fa-f]{6}\z/

  # MVP のシングルユーザー運用ではこれ以上ステータス列を増やしても
  # ボードが横に膨らむだけで実用性が下がるため、上限を設けて UI 側でも
  # 「+ 追加」ボタンを隠す（フロント定数 STATUS_MAX_COUNT と同期）。
  MAX_COUNT = 10

  # statuses → inquiries は 1 対多。ステータス削除時は紐づく inquiries が
  # 残っていればエラーで止め、上位レイヤで `move_to` 運用を促す
  # （docs/data-design.md の RESTRICT 方針に対応）。
  has_many :inquiries, dependent: :restrict_with_error

  validates :name,
            presence: true,
            length: { maximum: 100 }
  validates :color,
            presence: true,
            format: { with: HEX_COLOR_REGEX, message: "must be a hex color like #1A2B3C" }
  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # on: :create に限定する理由:
  #   - seeds.rb での初期 6 件投入や UC-07（編集）で既存レコードを update する場合に
  #     カウントを再評価して妨げないため。
  #   - 11 件目を作ろうとした瞬間にだけ 422 を返せばよい。
  validate :within_max_count, on: :create

  scope :ordered, -> { order(:position, :id) }

  private

  def within_max_count
    return if Status.count < MAX_COUNT
    errors.add(:base, :max_count_exceeded, message: "ステータスは最大 #{MAX_COUNT} 件までです")
  end
end
