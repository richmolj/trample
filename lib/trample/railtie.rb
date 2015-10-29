module Trample
  class Railtie < Rails::Railtie

    config.before_initialize do
      Trample::Search.extend ActiveModel::Naming
    end

  end
end
