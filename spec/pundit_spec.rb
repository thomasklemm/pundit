require "pundit"
require "pry"
require "active_record"
require "action_controller"

class PostPolicy < Struct.new(:user, :post)
  def update?
    post.user == user
  end
  def destroy?
    false
  end
  def show?
    true
  end
end
class PostPolicy::Scope < Struct.new(:user, :scope)
  def resolve
    scope.published
  end
end
class PostPolicy::Attributes < Struct.new(:user, :post)
  def permitted_attributes
    %w(title)
  end
end
class Post < Struct.new(:user)
  attr_accessor :title
  def self.published
    :published
  end
end

class CommentPolicy < Struct.new(:user, :comment); end
class CommentPolicy::Scope < Struct.new(:user, :scope)
  def resolve
    scope
  end
end
class CommentPolicy::Attributes < Struct.new(:user, :comment)
  def permitted_attributes
    %w(accessible_column virtual_column)
  end
end
class Comment < ActiveRecord::Base
  # The `comments` table has two columns
  # named `accessible_column` and `protected_column`

  attr_accessor :virtual_column
end

class Article; end

class BlogPolicy < Struct.new(:user, :blog); end
class Blog; end
class ArtificialBlog < Blog
  def self.policy_class
    BlogPolicy
  end
end
class ArticleTag
  def self.policy_class
    Struct.new(:user, :tag) do
      def show?
        true
      end
      def destroy?
        false
      end
    end
  end
end

def create_comments_table
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

  ActiveRecord::Schema.define(version: 1) do 
    create_table(:comments) do |t| 
      t.string :accessible_column
      t.string :protected_column
    end
  end
end

describe Pundit do
  before(:all) { create_comments_table }
  let(:user) { double }
  let(:post) { Post.new(user) }
  let(:comment) { Comment.new }
  let(:article) { Article.new }
  let(:controller) { double(:current_user => user, :params => { :action => "update" }).tap { |c| c.extend(Pundit) } }
  let(:artificial_blog) { ArtificialBlog.new }
  let(:article_tag) { ArticleTag.new }

  describe ".policy_scope" do
    it "returns an instantiated policy scope given a plain model class" do
      expect(Pundit.policy_scope(user, Post)).to eq :published
    end

    it "returns an instantiated policy scope given an active model class" do
      expect(Pundit.policy_scope(user, Comment)).to eq Comment
    end

    it "returns nil if the given policy scope can't be found" do
      expect(Pundit.policy_scope(user, Article)).to be_nil
    end
  end

  describe ".policy_scope!" do
    it "returns an instantiated policy scope given a plain model class" do
      expect(Pundit.policy_scope!(user, Post)).to eq :published
    end

    it "returns an instantiated policy scope given an active model class" do
      expect(Pundit.policy_scope!(user, Comment)).to eq Comment
    end

    it "throws an exception if the given policy scope can't be found" do
      expect { Pundit.policy_scope!(user, Article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "throws an exception if the given policy scope can't be found" do
      expect { Pundit.policy_scope!(user, ArticleTag) }.to raise_error(Pundit::NotDefinedError)
    end
  end

  describe ".policy_attributes" do
    it "returns instantiated policy attributes given a plain model class" do
      expect(Pundit.policy_attributes(user, Post)).to eq %w(title)
    end

    it "returns instantiated policy attributes given an active record class" do
      expect(Pundit.policy_attributes(user, Comment)).to match_array %w(accessible_column virtual_column)
    end

    it "returns nil if the given policy attributes can't be found" do
      expect(Pundit.policy_attributes(user, Article)).to be_nil
    end
  end

  describe ".policy_attributes!" do
    it "returns instantiated policy attributes given a plain model class" do
      expect(Pundit.policy_attributes!(user, Post)).to eq %w(title)
    end

    it "returns instantiated policy attributes given an active record class" do
      expect(Pundit.policy_attributes!(user, Comment)).to match_array %w(accessible_column virtual_column)
    end

    it "throws an exception if the given policy attributes can't be found" do
      expect { Pundit.policy_attributes!(user, Article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "throws an exception if the given policy attributes can't be found" do
      expect { Pundit.policy_attributes!(user, ArticleTag) }.to raise_error(Pundit::NotDefinedError)
    end
  end

  describe ".policy" do
    it "returns an instantiated policy given a plain model instance" do
      policy = Pundit.policy(user, post)
      expect(policy.user).to eq user
      expect(policy.post).to eq post
    end

    it "returns an instantiated policy given an active model instance" do
      policy = Pundit.policy(user, comment)
      expect(policy.user).to eq user
      expect(policy.comment).to eq comment
    end

    it "returns an instantiated policy given a plain model class" do
      policy = Pundit.policy(user, Post)
      expect(policy.user).to eq user
      expect(policy.post).to eq Post
    end

    it "returns an instantiated policy given an active model class" do
      policy = Pundit.policy(user, Comment)
      expect(policy.user).to eq user
      expect(policy.comment).to eq Comment
    end

    it "returns nil if the given policy can't be found" do
      expect(Pundit.policy(user, article)).to be_nil
      expect(Pundit.policy(user, Article)).to be_nil
    end

    describe "with .policy_class set on the model" do
      it "returns an instantiated policy given a plain model instance" do
        policy = Pundit.policy(user, artificial_blog)
        expect(policy.user).to eq user
        expect(policy.blog).to eq artificial_blog
      end

      it "returns an instantiated policy given a plain model class" do
        policy = Pundit.policy(user, ArtificialBlog)
        expect(policy.user).to eq user
        expect(policy.blog).to eq ArtificialBlog
      end

      it "returns an instantiated policy given a plain model instance providing an anonymous class" do
        policy = Pundit.policy(user, article_tag)
        expect(policy.user).to eq user
        expect(policy.tag).to eq article_tag
      end

      it "returns an instantiated policy given a plain model class providing an anonymous class" do
        policy = Pundit.policy(user, ArticleTag)
        expect(policy.user).to eq user
        expect(policy.tag).to eq ArticleTag
      end
    end
  end

  describe ".policy!" do
    it "returns an instantiated policy given a plain model instance" do
      policy = Pundit.policy!(user, post)
      expect(policy.user).to eq user
      expect(policy.post).to eq post
    end

    it "returns an instantiated policy given an active model instance" do
      policy = Pundit.policy!(user, comment)
      expect(policy.user).to eq user
      expect(policy.comment).to eq comment
    end

    it "returns an instantiated policy given a plain model class" do
      policy = Pundit.policy!(user, Post)
      expect(policy.user).to eq user
      expect(policy.post).to eq Post
    end

    it "returns an instantiated policy given an active model class" do
      policy = Pundit.policy!(user, Comment)
      expect(policy.user).to eq user
      expect(policy.comment).to eq Comment
    end

    it "throws an exception if the given policy can't be found" do
      expect { Pundit.policy!(user, article) }.to raise_error(Pundit::NotDefinedError)
      expect { Pundit.policy!(user, Article) }.to raise_error(Pundit::NotDefinedError)
    end
  end

  describe "#verify_authorized" do
    it "does nothing when authorized" do
      controller.authorize(post)
      controller.verify_authorized
    end

    it "raises an exception when not authorized" do
      expect { controller.verify_authorized }.to raise_error(Pundit::AuthorizationNotPerformedError)
    end
  end

  describe "#verify_policy_scoped" do
    it "does nothing when policy_scope is used" do
      controller.policy_scope(Post)
      controller.verify_policy_scoped
    end

    it "raises an exception when policy_scope is not used" do
      expect { controller.verify_policy_scoped }.to raise_error(Pundit::AuthorizationNotPerformedError)
    end
  end

  describe "#authorize" do
    it "infers the policy name and authorized based on it" do
      expect(controller.authorize(post)).to be_truthy
    end

    it "can be given a different permission to check" do
      expect(controller.authorize(post, :show?)).to be_truthy
      expect { controller.authorize(post, :destroy?) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "works with anonymous class policies" do
      expect(controller.authorize(article_tag, :show?)).to be_truthy
      expect { controller.authorize(article_tag, :destroy?) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises an error when the permission check fails" do
      expect { controller.authorize(Post.new) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises an error with a query and action" do
      expect { controller.authorize(post, :destroy?) }.to raise_error do |error|
        expect(error.query).to eq :destroy?
        expect(error.record).to eq post
        expect(error.policy).to eq controller.policy(post)
      end
    end
  end

  describe "#pundit_user" do
    it 'returns the same thing as current_user' do
      expect(controller.pundit_user).to eq controller.current_user
    end
  end

  describe ".policy" do
    it "returns an instantiated policy" do
      policy = controller.policy(post)
      expect(policy.user).to eq user
      expect(policy.post).to eq post
    end

    it "throws an exception if the given policy can't be found" do
      expect { controller.policy(article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "allows policy to be injected" do
      new_policy = OpenStruct.new
      controller.policy = new_policy

      expect(controller.policy(post)).to eq new_policy
    end
  end

  describe ".policy_scope" do
    it "returns an instantiated policy scope" do
      expect(controller.policy_scope(Post)).to eq :published
    end

    it "throws an exception if the given policy can't be found" do
      expect { controller.policy_scope(Article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "allows policy_scope to be injected" do
      new_scope = OpenStruct.new
      controller.policy_scope = new_scope

      expect(controller.policy_scope(post)).to eq new_scope
    end
  end

  describe ".policy_attributes" do
    it "returns instantiated policy attributes given a class" do
      expect(controller.policy_attributes(Post)).to eq %w(title)
    end

    it "returns instantiated policy attributes given an instantiated record" do
      expect(controller.policy_attributes(post)).to eq %w(title)
    end

    it "returns instantiated policy attributes given a symbol" do
      expect(controller.policy_attributes(:post)).to eq %w(title)
    end

    it "throws an exception if the given policy can't be found" do
      expect { controller.policy_attributes(Article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "allows policy_attributes to be injected" do
      new_attributes = OpenStruct.new
      controller.policy_attributes = new_attributes

      expect(controller.policy_attributes(post)).to eq new_attributes
    end
  end

  describe ".policy_params" do
    context "in a Rails controller" do
      let(:permitted_post_params) { { 'title' => 'title' } }
      let(:post_params) { { :title => 'title', :body => 'body' } }

      let(:controller) do 
        controller = ActionController::Base.new.tap { |c| c.extend(Pundit) }
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:params).and_return(:post => post_params)
        controller
      end

      let(:permitted_post_params) do
        { 'title' => 'title' }
      end

      it "returns permitted params given a symbol" do
        expect(controller.policy_params(:post)).to eq permitted_post_params
      end

      it "returns permitted params given a class" do
        expect(controller.policy_params(Post)).to eq permitted_post_params
      end

      it "returns permitted params given an instantiated record" do
        expect(controller.policy_params(post)).to eq permitted_post_params
      end
    end

    context "outside of a Rails controller" do
      let(:permitted_post_params) { { 'title' => 'title' } }
      let(:post_params) { { :title => 'title', :body => 'body' } }
      let(:controller) { double(:current_user => user, :params => { :action => "update", :post => post_params }).tap { |c| c.extend(Pundit) } }

      it "returns permitted params given a symbol" do
        expect(controller.policy_params(:post)).to eq permitted_post_params
      end

      it "returns permitted params given a class" do
        expect(controller.policy_params(Post)).to eq permitted_post_params
      end

      it "returns permitted params given an instantiated record" do
        expect(controller.policy_params(post)).to eq permitted_post_params
      end
    end
  end
end
