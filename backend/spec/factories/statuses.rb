FactoryBot.define do
  factory :status do
    sequence(:name) { |n| "Status #{n}" }
    color { "#3498DB" }
    sequence(:position) { |n| n - 1 } # 0 始まり連番
  end
end
