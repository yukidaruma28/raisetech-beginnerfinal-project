FactoryBot.define do
  factory :inquiry do
    association :status
    sequence(:title) { |n| "Inquiry #{n}" }
    description      { "サンプル本文" }
    sequence(:position) { |n| n - 1 } # 同 status 内では明示的に position を指定して使う
  end
end
