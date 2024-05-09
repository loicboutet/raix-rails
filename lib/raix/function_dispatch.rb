# frozen_string_literal: true

# Provides declarative function definition for ChatCompletion classes.
#
# Example:
#
#   class MeaningOfLife
#     include Raix::ChatCompletion
#     include Raix::FunctionDispatch
#
#     function :ask_deep_thought do
#       wait 236_682_000_000_000
#       "The meaning of life is 42"
#     end
#
#     def initialize
#       transcript << { user: "What is the meaning of life?" }
#       chat_completion
#     end
#   end
module FunctionDispatch
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :functions

    # Defines a function that can be dispatched by the ChatCompletion module while
    # processing the response from an AI model.
    #
    # Declaring a function here will automatically add it (in JSON Schema format) to
    # the list of tools provided to the OpenRouter Chat Completion API. The function
    # will be dispatched by name, so make sure the name is unique. The function's block
    # argument will be executed in the instance context of the class that includes this module.
    #
    # Example:
    #   function :google_search, description: "Search Google for something", query: { type: "string" } do |arguments|
    #     GoogleSearch.new(arguments[:query]).search
    #   end
    #
    # @param name [Symbol] The name of the function.
    # @param description [String] An optional description of the function.
    # @param parameters [Hash] The parameters that the function accepts.
    # @param block [Proc] The block of code to execute when the function is called.
    def function(name, description: nil, **parameters, &block) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      @functions ||= []
      @functions << begin
        { type: "function", function: { name:, parameters: { type: "object", properties: {} } } }.tap do |definition|
          definition[:function][:description] = description if description.present?
          parameters.map do |key, value|
            definition[:function][:parameters][:properties][key] = value
          end
        end
      end

      define_method(name) do |arguments|
        transcript << { function: { name:, arguments: } }
        instance_exec(arguments, &block).tap do |result|
          transcript << { assistant: result }
        end
      end
    end

    def tools
      self.class.functions
    end
  end
end
