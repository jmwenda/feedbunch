require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user,
                               quick_reading: false,
                               open_all_entries: false,
                               show_main_tour: false,
                               show_mobile_tour: false,
                               show_feed_tour: false,
                               show_entry_tour: false
    @old_config_etag = @user.reload.config_etag
  end

  context 'touches config' do

    it 'when quick_reading is updated' do
      @user.update quick_reading: true
      expect(@user.reload.config_etag).not_to eq @old_config_etag
    end

    it 'when open_all_entries is updated' do
      @user.update open_all_entries: true
      expect(@user.reload.config_etag).not_to eq @old_config_etag
    end

    it 'when show_main_tour is updated' do
      @user.update show_main_tour: true
      expect(@user.reload.config_etag).not_to eq @old_config_etag
    end

    it 'when show_mobile_tour is updated' do
      @user.update show_mobile_tour: true
      expect(@user.reload.config_etag).not_to eq @old_config_etag
    end

    it 'when show_feed_tour is updated' do
      @user.update show_feed_tour: true
      expect(@user.reload.config_etag).not_to eq @old_config_etag
    end

    it 'when show_entry_tour is updated' do
      @user.update show_entry_tour: true
      expect(@user.reload.config_etag).not_to eq @old_config_etag
    end
  end

  context 'does not touch config' do
    it 'when other attributes are updated' do
      @user.update email: 'another_email@email.com'
      expect(@user.reload.config_etag).to eq @old_config_etag
    end
  end
end