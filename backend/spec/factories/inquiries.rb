FactoryBot.define do
  factory :inquiry do
    association :status
    # priority は必須（3 段階 + デフォルト「低」）。
    # Priority は level UNIQUE 制約があるため、テスト内で複数 Inquiry を作成しても
    # priority レコードを共有する。最初の build 時に level=1 で作成し、以降は再利用。
    # テストで個別 priority を渡したい場合は明示的に指定する: create(:inquiry, priority: foo)
    priority { Priority.first || create(:priority, level: 1) }
    sequence(:title) { |n| "Inquiry #{n}" }
    description      { "サンプル本文" }
    sequence(:position) { |n| n - 1 } # 同 status 内では明示的に position を指定して使う
  end
end
