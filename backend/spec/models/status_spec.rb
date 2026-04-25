require 'rails_helper'

RSpec.describe Status, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:status)).to be_valid
    end

    it 'requires name' do
      status = build(:status, name: nil)
      expect(status).not_to be_valid
      expect(status.errors[:name]).to include("can't be blank")
    end

    it 'rejects empty name' do
      status = build(:status, name: '')
      expect(status).not_to be_valid
    end

    it 'requires color' do
      status = build(:status, color: nil)
      expect(status).not_to be_valid
    end

    it 'rejects invalid hex color' do
      %w[red #FFF #GGGGGG #1234567 1A2B3C].each do |bad|
        status = build(:status, color: bad)
        expect(status).not_to be_valid, "expected #{bad.inspect} to be invalid"
      end
    end

    it 'accepts valid hex color' do
      %w[#000000 #ffffff #1A2B3C #abcdef].each do |good|
        status = build(:status, color: good)
        expect(status).to be_valid, "expected #{good.inspect} to be valid"
      end
    end

    it 'requires position to be >= 0' do
      status = build(:status, position: -1)
      expect(status).not_to be_valid
    end

    it 'requires position to be an integer' do
      status = build(:status, position: 1.5)
      expect(status).not_to be_valid
    end
  end

  describe '.ordered' do
    it 'returns statuses ordered by position ascending' do
      a = create(:status, name: 'A', position: 2)
      b = create(:status, name: 'B', position: 0)
      c = create(:status, name: 'C', position: 1)

      expect(Status.ordered.map(&:name)).to eq(%w[B C A])
    end
  end
end
