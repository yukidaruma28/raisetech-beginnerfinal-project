require 'rails_helper'

RSpec.describe Priority, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:priority)).to be_valid
    end

    it 'requires name' do
      priority = build(:priority, name: nil)
      expect(priority).not_to be_valid
      expect(priority.errors[:name]).to include("can't be blank")
    end

    it 'requires level' do
      priority = build(:priority, level: nil)
      expect(priority).not_to be_valid
    end

    it 'rejects level outside 1..3' do
      [-1, 0, 4, 5, 100].each do |bad|
        priority = build(:priority, level: bad)
        expect(priority).not_to be_valid, "expected level=#{bad} to be invalid"
      end
    end

    it 'accepts level 1..3' do
      (1..3).each do |good|
        priority = build(:priority, level: good)
        expect(priority).to be_valid, "expected level=#{good} to be valid"
      end
    end

    it 'enforces level uniqueness' do
      create(:priority, level: 1)
      duplicate = build(:priority, level: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:level]).to include('has already been taken')
    end

    it 'rejects invalid hex color' do
      %w[red #FFF #GGGGGG 1A2B3C].each do |bad|
        priority = build(:priority, color: bad)
        expect(priority).not_to be_valid, "expected #{bad.inspect} to be invalid"
      end
    end

    it 'requires position to be >= 0' do
      priority = build(:priority, position: -1)
      expect(priority).not_to be_valid
    end
  end

  describe '.ordered' do
    it 'returns priorities ordered by position ascending' do
      a = create(:priority, level: 3, position: 2)
      b = create(:priority, level: 1, position: 0)
      c = create(:priority, level: 2, position: 1)

      expect(Priority.ordered.map(&:level)).to eq([1, 2, 3])
    end
  end

  describe 'association with inquiries' do
    it 'prevents destroying priority that has associated inquiries (restrict_with_error)' do
      priority = create(:priority, level: 1)
      status   = create(:status)
      create(:inquiry, status: status, priority: priority)

      expect(priority.destroy).to be_falsy
      expect(priority.errors[:base]).to be_present
    end

    it 'allows destroying priority that has no associated inquiries' do
      priority = create(:priority, level: 1)
      expect(priority.destroy).to be_truthy
    end
  end
end
