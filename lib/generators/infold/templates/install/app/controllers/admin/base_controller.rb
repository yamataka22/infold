module Admin
  class BaseController < ActionController::Base
    class Forbidden < ActionController::ActionControllerError; end
    include ErrorHandlers

    layout 'admin'

    before_action :turbo_frame_request_variant
    before_action :authenticate_admin_user!

    private

    def turbo_frame_request_variant
      request.variant = :turbo_frame if turbo_frame_request?
    end
  end
end