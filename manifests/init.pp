# Class: java
#
# Parameters:
#   The parameters listed here are not required in general and were
#     added for use cases related to development environments.
#   with_maven - whether or not install maven (default: false)
#   with_ant   - whether or not install ant (default: false)
# Actions:
#
# Requires:
#   puppetlabs/apt
#
# Sample Usage:
#  class { 'devtools':
#    ide => 'IntelliJ',
#    packages => [ 'cvs' ]
#  }

class devtools(
  $ide = [],
  $packages = []
) {
  # that's a bit of a nasty hack to compensate for a lack of a simple foreach loop :/
  ide     { $ide: }
  package { $packages: ensure => present; }


  # helper types

  define ide() {
    $ide = split($name, ' ')

    $ide_name    = $ide[0]
    $ide_version = $ide[1]

    case $ide_name {
      intellij: { ide_intellij { $ide_version: } }
      eclipse:  { ide_eclipse  { $ide_version: } }
    }
  }

  # juno-SR1
  define ide_eclipse() {
    # this assumes that the version is something like "juno-SR1"; might need to be revisited later
    $version = split($name, "-")

    $downloadable = "eclipse-jee-${version[0]}-${version[1]}-linux-gtk-x86_64.tar.gz"
    $site          = "http://eclipse.yatta.de/technology/epp/downloads/release/${version[0]}/${version[1]}"

    install_ide { 'Eclipse':
      downloadable    => $downloadable,
      site            => $site,
      executable_path => '',
      executable_name => 'eclipse',
      symlink_name    => 'eclipse'
    }
  }

  define ide_intellij() {
    $downloadable = "ideaIU-${name}.tar.gz"
    $site         = "http://download.jetbrains.com/idea"

    install_ide { 'IntelliJ':
      downloadable    => $downloadable,
      site            => $site,
      executable_path => 'bin',
      executable_name => 'idea.sh',
      symlink_name    => 'idea'
    }
  }

  define install_ide(
    $downloadable    = 'UNSET',
    $site            = 'UNSET',
    $executable_path = '',
    $executable_name = 'UNSET',
    $symlink_name    = 'UNSET'
  ) {
    $temp_dir     = "/tmp"
    $install_dir  = "/opt"

    $ide_dir_file_name = "${name}_dir"

    $executable   = join([$executable_path, $executable_name], "/")

    download_file { $downloadable: site => $site, cwd => $temp_dir }

    exec { "Get ${name} dir name":
      command => "tar -ztf ${downloadable} | grep -o -E '^[-A-Za-z0-9\\._]+' | uniq > ${temp_dir}/${ide_dir_file_name}",
      cwd     => $temp_dir,
      creates => "${temp_dir}/${ide_dir_file_name}",
      require => Download_file[$downloadable]
    }

    exec { "Untar ${name}":
      command => "tar xfz ${temp_dir}/${downloadable}",
      cwd     => "${install_dir}",
      require => Exec["Get ${name} dir name"],
      unless  => "ls `cat ${temp_dir}/${ide_dir_file_name}` 2>/dev/null"
    }

    exec { "Link the ${name} binary":
      command => "ln -s ${install_dir}/`cat ${temp_dir}/${ide_dir_file_name}`/${executable} /usr/local/bin/${symlink_name}",
      require => Exec["Untar ${name}"],
      creates => "/usr/local/bin/${symlink_name}"
    }
  }

  define download_file($site = '', $cwd = '/tmp', $user = 'root') {
    exec { $name:
      command => "wget ${site}/${name}",
      cwd     => $cwd,
      creates => "${cwd}/${name}",
      user    => $user,
      timeout => 0
    }
  }
}