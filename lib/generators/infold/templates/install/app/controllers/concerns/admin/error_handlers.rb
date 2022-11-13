module Admin
  module ErrorHandlers
    extend ActiveSupport::Concern

    included do
      rescue_from Exception, with: :rescue500
      rescue_from ActionController::ParameterMissing, with: :rescue400
      rescue_from BaseController::Forbidden, with: :rescue403
      rescue_from ActionController::RoutingError, with: :rescue404
      rescue_from ActiveRecord::RecordNotFound, with: :rescue404
    end

    private

    def rescue400(e)
      @exception = e
      render '/admin/errors/bad_request', status: 400
    end

    def rescue403(e)
      @exception = e
      render '/admin/errors/forbidden', status: 403
    end

    def rescue404(e)
      @exception = e
      render '/admin/errors/not_found', status: 404
    end

    def rescue500(e)
      @exception = e
      logger.fatal e.message
      logger.fatal e.backtrace.join("\n")
      if Rails.env.production?
        render '/admin/errors/admin_server_error', status: 500
      else
        raise e
      end
    end
  end
end