require "pundit/version"
require "pundit/policy_finder"
require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/keys"

module Pundit
  class NotAuthorizedError < StandardError
    attr_accessor :query, :record, :policy
  end
  class AuthorizationNotPerformedError < StandardError; end
  class NotDefinedError < StandardError; end

  extend ActiveSupport::Concern

  class << self
    def policy_scope(user, scope)
      policy_scope = PolicyFinder.new(scope).scope
      policy_scope.new(user, scope).resolve if policy_scope
    end

    def policy_scope!(user, scope)
      PolicyFinder.new(scope).scope!.new(user, scope).resolve
    end

    def policy_attributes(user, record)
      policy_attributes = PolicyFinder.new(record).attributes
      policy_attributes.new(user, record).permitted_attributes if policy_attributes
    end

    def policy_attributes!(user, record)
      PolicyFinder.new(record).attributes!.new(user, record).permitted_attributes
    end

    def policy(user, record)
      policy = PolicyFinder.new(record).policy
      policy.new(user, record) if policy
    end

    def policy!(user, record)
      PolicyFinder.new(record).policy!.new(user, record)
    end
  end

  included do
    if respond_to?(:helper_method)
      helper_method :policy
      helper_method :policy_scope
      helper_method :policy_attributes
      helper_method :policy_params
      helper_method :pundit_user
    end
    if respond_to?(:hide_action)
      hide_action :policy
      hide_action :policy=
      hide_action :policy_scope
      hide_action :policy_scope=
      hide_action :policy_attributes
      hide_action :policy_attributes=
      hide_action :authorize
      hide_action :verify_authorized
      hide_action :verify_policy_scoped
      hide_action :policy_params
      hide_action :pundit_user
    end
  end

  def verify_authorized
    raise AuthorizationNotPerformedError unless @_policy_authorized
  end

  def verify_policy_scoped
    raise AuthorizationNotPerformedError unless @_policy_scoped
  end

  def authorize(record, query=nil)
    query ||= params[:action].to_s + "?"
    @_policy_authorized = true

    policy = policy(record)
    unless policy.public_send(query)
      error = NotAuthorizedError.new("not allowed to #{query} this #{record}")
      error.query, error.record, error.policy = query, record, policy

      raise error
    end

    true
  end

  def policy_scope(scope)
    @_policy_scoped = true
    @policy_scope or Pundit.policy_scope!(pundit_user, scope)
  end
  attr_writer :policy_scope

  def policy_attributes(symbol_or_record)
    @policy_attributes or Pundit.policy_attributes!(pundit_user, symbol_or_record)
  end
  attr_writer :policy_attributes

  def policy_params(symbol_or_record)
    symbol = if symbol_or_record.is_a?(Symbol)
      symbol_or_record
    else
      PolicyFinder.new(symbol_or_record).params_key
    end

    permitted_attributes = policy_attributes(symbol_or_record).map(&:to_s)

    if defined?(ActionController::Parameters)
      binding.pry
      parameters = ActionController::Parameters.new(params)
      parameters.require(symbol).permit(*permitted_attributes)
    else
      attributes = params.fetch(symbol) { raise "Missing params[#{symbol}]" }
      attributes.stringify_keys.slice(*permitted_attributes)
    end
  end

  def policy(record)
    @policy or Pundit.policy!(pundit_user, record)
  end
  attr_writer :policy

  def pundit_user
    current_user
  end
end
