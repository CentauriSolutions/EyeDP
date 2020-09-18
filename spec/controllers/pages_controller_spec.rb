# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  context 'Home page' do
    render_views

    it 'renders template' do
      Setting.home_template = 'Hello, Rspec!'
      get :home
      expect(response.body).to include('Hello, Rspec!')
    end
  end
end
