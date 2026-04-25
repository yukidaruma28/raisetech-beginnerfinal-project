require 'rails_helper'

RSpec.describe Inquiry, type: :model do
  describe 'associations' do
    it 'belongs_to :status' do
      assoc = described_class.reflect_on_association(:status)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:inquiry)).to be_valid
    end

    it 'requires title' do
      inquiry = build(:inquiry, title: nil)
      expect(inquiry).not_to be_valid
      expect(inquiry.errors[:title]).to include("can't be blank")
    end

    it 'rejects empty title' do
      inquiry = build(:inquiry, title: '')
      expect(inquiry).not_to be_valid
    end

    it 'rejects title longer than 255 chars' do
      inquiry = build(:inquiry, title: 'a' * 256)
      expect(inquiry).not_to be_valid
    end

    it 'requires status' do
      inquiry = build(:inquiry, status: nil)
      expect(inquiry).not_to be_valid
    end

    it 'allows nil description' do
      inquiry = build(:inquiry, description: nil)
      expect(inquiry).to be_valid
    end

    it 'requires position to be >= 0' do
      inquiry = build(:inquiry, position: -1)
      expect(inquiry).not_to be_valid
    end

    it 'requires position to be an integer' do
      inquiry = build(:inquiry, position: 1.5)
      expect(inquiry).not_to be_valid
    end
  end

  describe '.ordered' do
    it 'returns inquiries ordered by status_id then position' do
      backlog = create(:status, name: 'Backlog', position: 0)
      todo    = create(:status, name: 'Todo',    position: 1)

      a = create(:inquiry, status: todo,    position: 1, title: 'A')
      b = create(:inquiry, status: backlog, position: 1, title: 'B')
      c = create(:inquiry, status: todo,    position: 0, title: 'C')
      d = create(:inquiry, status: backlog, position: 0, title: 'D')

      expect(Inquiry.ordered.map(&:title)).to eq(%w[D B C A])
    end
  end

  describe 'Status#inquiries' do
    it 'restricts deletion when inquiries are present' do
      status = create(:status)
      create(:inquiry, status: status)

      expect(status.destroy).to be_falsey
      expect(status.errors[:base].join).to match(/restrict|cannot|削除/i).or include("Cannot delete record because dependent inquiries exist")
    end
  end
end
