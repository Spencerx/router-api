require 'rails_helper'
require Rails.root.join('app/models/route')

RSpec.describe RoutesController, type: :controller do
  before do
    FactoryBot.create(:backend, backend_id: "a-backend")
  end

  let(:data) {
    {
      route: {
        incoming_path: "/foo/bar", route_type: "prefix", handler: "backend", backend_id: "a-backend"
      }
    }.to_json
  }

  it "should not fail on multiple simultaneous requests" do
    bypass_rescue
    failed = false

    threads = 4.times.map do
      Thread.new do
        begin
          put :update, body: data, format: :json
        rescue Mongo::Error::OperationFailure
          failed = true
        # rubocop:disable Lint/HandleExceptions
        rescue AbstractController::DoubleRenderError
          # this error will happen if both threads succeed, so this is fine.
        end
      end
      # rubocop:enable Lint/HandleExceptions
    end
    threads.each(&:join)

    expect(failed).to be false
  end
end
