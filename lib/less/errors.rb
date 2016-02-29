require 'yaml'

module Less

  class ParseError < ::StandardError

    def initialize(details)
      @details = YAML.load(details.gsub('=>', ':'))
      super(@details['message'])
    end

    def method_missing(name, *args, &block)
      key = name.to_s
      super unless @details.has_key?(key)
      @details[key]
    end

  end

end
