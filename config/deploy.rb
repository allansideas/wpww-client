set :application, "woww"

set :repository, "deploy_package.tar.gz"
set :scm, :none 

set :use_sudo,    false

ssh_options[:forward_agent] = true
#default_run_options[:pty] = true
set :default_stage, "staging"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

set :deploy_to, "/home/#{application}/client/"
task :staging do
  role :web, "woww@taglich.instantiate.me"
  role :app, "woww@taglich.instantiate.me"
  set :deploy_to, "/home/#{application}/client/"
end

namespace :deploy do
  task :build do
    system "grunt --force"
  end

  task :compress do
    system "tar -zcvf deploy_package.tar.gz dist"
  end

  task :upload do
    system("scp -r deploy_package.tar.gz woww@taglich.instantiate.me:#{deploy_to}/deploy_package.tar.gz")
  end

  task :update_code do
    run "mkdir #{release_path}"
    run "cp -R #{deploy_to}deploy_package.tar.gz #{release_path}/"
  end

  task :uncompress_and_clean_up do
    run "cd #{release_path} && tar -zxvf deploy_package.tar.gz --strip-components=1"
    #run "mv #{release_path}/dist/* #{release_path}/"
  end

  task :symlinks do
    run "ln -nfs #{shared_path}/fonts #{release_path}/styles/fonts"
  end

  before "deploy:update_code", "deploy:build"
  after "deploy:build", "deploy:compress"
  after "deploy:compress", "deploy:upload"
  after "deploy:update_code", "deploy:uncompress_and_clean_up"
  after "deploy:uncompress_and_clean_up", "deploy:symlinks"
end
