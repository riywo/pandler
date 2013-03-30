#!/bin/bash
vagrant_dir="/vagrant"
root_dir="/root/pandler"

if ! ruby -v; then
  yum install -y ruby
fi

if ! gem -v; then
  yum install -y rubygems
fi

if ! bundle -v; then
  gem install bundler
fi

if ! git --version; then
  yum install -y git
fi

mkdir -p $root_dir
cd $root_dir
for i in lib spec etc Gemfile Rakefile pandler.gemspec .git .gitignore LICENSE.txt README.md Vagrantfile vagrant_file.sh; do
  ln -sf "$vagrant_dir/$i" .
done
mkdir -p "$root_dir/bin"
ln -sf "$vagrant_dir/bin/pandle" bin/pandle

bundle install --path vendor/bundle
bundle exec pandle help
