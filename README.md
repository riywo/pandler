# Pandler
Manage your packages with chroot.

Pandler(= Package + Bundler) helps managing rpm/yum packages. Using `Yumfile` and `Yumfile.lock`, Pandler automatically creates a locked chroot environment.

## Installation

*Currently Pandler support only root user usage because of `mount`. You should install and run as root user.*

Add this line to your application's Gemfile:

    gem 'pandler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pandler

## Usage

Write `Yumfile`.

    repo "base", "http://vault.centos.org/6.2/os/x86_64/"

    rpm "basesystem"
    rpm "coreutils"

Run `pandle install`.

    # pandle install
    # pandle list

Then, you can execute any command in the chroot environment.

    # pandle exec pwd
    /

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
