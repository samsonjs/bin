#!/usr/bin/env ruby

HomePath = File.expand_path('~') # better way to do this?
ProjectsPath = File.join(HomePath, 'Projects')

def git_repos_in(path, recurse=true)
  dirs = Dir[File.join(path, '*')].select do |path|
    File.directory?(path)
  end
  if recurse
    dirs.map do |path|
      # add subdirs to the list but ignore subdirs of git repos
      [path] + (git_repo?(path) ? [] : git_repos_in(path, true))
    end.flatten
  else    
    dirs
  end.select { |path| git_repo?(path) }
end

def git_dir_in(path)
  gitpath = File.join(path, '.git')
  File.exists?(gitpath) ? gitpath : nil
end

alias git_repo? git_dir_in

git_repos_in(ProjectsPath).each do |path|
  puts path
end