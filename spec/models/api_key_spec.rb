# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  let(:empty_key) { ApiKey.create }

  describe 'key without permissions' do
    it "can't list_groups" do
      expect(empty_key.list_groups?).to be false
    end
    it "can't read_group" do
      expect(empty_key.read_group?).to be false
    end
    it "can't write_group" do
      expect(empty_key.write_group?).to be false
    end
    it "can't list_users" do
      expect(empty_key.list_users?).to be false
    end
    it "can't read_user" do
      expect(empty_key.read_user?).to be false
    end
    it "can't write_user" do
      expect(empty_key.write_user?).to be false
    end
    it "can't read_group_members" do
      expect(empty_key.read_group_members?).to be false
    end
    it "can't write_group_members" do
      expect(empty_key.write_group_members?).to be false
    end
    it "can'tcontrol admin groups" do
      expect(empty_key.control_admin_groups?).to be false
    end

    it 'can enable list_groups' do
      expect(empty_key.list_groups?).to be false
      empty_key.list_groups!
      expect(empty_key.list_groups?).to be true
    end
    it 'can enable read_group' do
      expect(empty_key.read_group?).to be false
      empty_key.read_group!
      expect(empty_key.read_group?).to be true
    end
    it 'can enable write_group' do
      expect(empty_key.write_group?).to be false
      empty_key.write_group!
      expect(empty_key.write_group?).to be true
    end
    it 'can enable list_users' do
      expect(empty_key.list_users?).to be false
      empty_key.list_users!
      expect(empty_key.list_users?).to be true
    end
    it 'can enable read_user' do
      expect(empty_key.read_user?).to be false
      empty_key.read_user!
      expect(empty_key.read_user?).to be true
    end
    it 'can enable write_user' do
      expect(empty_key.write_user?).to be false
      empty_key.write_user!
      expect(empty_key.write_user?).to be true
    end
    it 'can enable read_group_members' do
      expect(empty_key.read_group_members?).to be false
      empty_key.read_group_members!
      expect(empty_key.read_group_members?).to be true
    end
    it 'can enable write_group_members' do
      expect(empty_key.write_group_members?).to be false
      empty_key.write_group_members!
      expect(empty_key.write_group_members?).to be true
    end
    it 'can enable read_custom attributes' do
      expect(empty_key.read_custom_data?).to be false
      empty_key.read_custom_data!
      expect(empty_key.read_custom_data?).to be true
    end
    it 'can enable write_custom attributes' do
      expect(empty_key.write_custom_data?).to be false
      empty_key.write_custom_data!
      expect(empty_key.write_custom_data?).to be true
    end
    it 'can enable control_admin_groups' do
      expect(empty_key.control_admin_groups?).to be false
      empty_key.control_admin_groups!
      expect(empty_key.control_admin_groups?).to be true
    end

    it 'can restrict custom attributes' do
      expect(empty_key.matching_custom_data(%w[name age])).to be false
      empty_key.custom_data = %w[name age birthday]
      expect(empty_key.matching_custom_data(%w[name age])).to be true
    end
  end
end
