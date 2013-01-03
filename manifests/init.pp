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
  $ide = 'UNSET',
  $packages = []
) {
  package { $packages: ensure => present; }

  case $ide {
    intellij: { install_intellij { '12.0.1': } }
    eclipse: {
      fail("Sorry, I haven't implemented eclipse support yet :( Stay tuned!")
    }
  }

  define install_intellij() {
    $downloadable = "ideaIU-${name}.tar.gz"
    $temp_dir     = "/tmp"
    $install_dir  = "/opt"

    download_file { $downloadable: site => "http://download.jetbrains.com/idea", cwd => $temp_dir }

    exec { "Get IntelliJ dir name":
      command => "tar -ztf ${downloadable} | grep -o -E '^[-A-Za-z0-9\\._]+' | uniq > ${temp_dir}/intellij_dir",
      cwd     => $temp_dir,
      creates => "${temp_dir}/intellij_dir",
      require => Download_file[$downloadable]
    }

    exec { "Untar IntelliJ":
      command => "tar xfz ${temp_dir}/${downloadable}",
      cwd     => "${install_dir}",
      require => Exec['Get IntelliJ dir name'],
      unless  => "ls `cat ${temp_dir}/intellij_dir` 2>/dev/null"
    }

    exec { "Link the IntelliJ binary":
      command => "ln -s ${install_dir}/`cat ${temp_dir}/intellij_dir`/bin/idea.sh /usr/local/bin/idea",
      require => Exec['Untar IntelliJ'],
      creates => "/usr/local/bin/idea"
    }
  }

  define download_file($site = '', $cwd = '/tmp', $user = 'root') {
    exec { $name:
      command => "wget ${site}/${name}",
      cwd     => $cwd,
      creates => "${cwd}/${name}",
      user    => $user
    }
  }
}