module Silverpop
  class SilverpopError < RuntimeError
  end
  class MissingParametersError < SilverpopError
  end
end