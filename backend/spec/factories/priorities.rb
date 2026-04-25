FactoryBot.define do
  factory :priority do
    # 3 段階 (高/中/低) 運用: level は 1..3 で循環。
    # 個別テストで特定の level を使いたい場合は明示的に渡す。
    sequence(:level) { |n| ((n - 1) % 3) + 1 }
    name { "Priority L#{level}" }
    color { "#E67E22" }
    sequence(:position) { |n| n - 1 }
  end
end
