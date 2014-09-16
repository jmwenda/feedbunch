require 'rails_helper'

describe 'application tours', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'main application tour' do

    context 'first time users' do

      before :each do
        @user.update show_main_tour: true
        login_user_for_feature @user
      end

      it 'shows the tour', js: true do
        tour_should_be_visible 'Start'
      end

      it 'does not show the tour after finishing it', js: true do
        while page.has_css? '.hopscotch-next'
          find('.hopscotch-next').click
        end
        tour_should_not_be_visible

        visit read_path
        # wait for client code to initialize
        sleep 1
        tour_should_not_be_visible
      end

      it 'does not show the tour after forcibly closing it'

    end

    context 'returning users' do

      it 'does not show the tour'

      it 'starts the tour again'
    end
  end
end