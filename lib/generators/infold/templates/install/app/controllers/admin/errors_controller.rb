module Admin
  class ErrorsController < BaseController
    def routing_error
      raise ActionController::RoutingError,
            "No routes matches #{request.path.inspect}"
    end
  end
end