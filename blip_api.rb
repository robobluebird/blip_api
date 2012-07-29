require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'haml'

class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name
  field :email
  field :password_hash

  has_many :files
end

class File
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :type
  field :data
end

configure do
  Mongoid.load!("mongoid.yml")
end

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
  end
end

get '/' do
  'hey y\'all'
end

get '/users' do
  @users = User.all

  [200, @users.to_json]
end

post '/users' do
  # create a new user
  user = User.new(
    first_name: params[:first_name],
    email: params[:email],
    password_hash: params[:password_hash]
  )

  if (user.save)
    [201, "/users/#{user.id}"]
  else
    500
  end
end

get '/users/:user' do
  # retrieve a user infos
  user = User.find(params[:id])

  if user
    [200, user.to_json]
  else
    404
  end
end

post '/users/:user/files' do |user_id|
  # add base64 bin to user's bins
  user = User.find(params[:user])

  if user
    file = user.files.new(
      name: params[:name],
      type: params[:type],
      data: params[:data]
    )

    if file
      [201, "/users/#{user.id}/files/#{file.id}"]
    else
      500
    end
  else
    404
  end
end

get '/users/:user/files/:file' do |user_id, file_id|
  # retreive an offered file
  user = User.find(params[:user])

  if user
    file = user.files.find(params[:file])

    if file
      [200, file.data]
    else
      404
    end
  end
end
