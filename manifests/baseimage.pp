# Class: vclmgmt::baseimage
#
# This class defines related vcl_image and xcat::image objects for a base image within xCAT and VCL
#
# Parameters:
# [*ensure*] 
#   - Passthrough for ensurable objects in this class
#     Defaults to present
# [*prettyname*] 
#   - Long display name for this image in VCL
# [*platform*] 
#   - VCL platform attribution for this image (may be i386, i386_lab, or ultrasparc)
#     Defaults to 'i386'
# [*os*] 
#   - OS of this image 
# [*minram*] 
#   - Min RAM requirement for this image
#     Defaults to 512
# [*minprocnumber*] 
#   - Min number of processors requirement for this image
#     Defaults to 1
# [*minprocspeed*] 
#   - Min processor speed requirement for this image
#     Defaults to 1024
# [*minnetwork*] 
#   - Min network speed requirement for this image
#     Defaults to 100
# [*maxconcurrent*] 
#   - maximum concurrent reservations that can be made for image
#     Defaults to undef
# [*test*] 
#   - flag to show if there is a test version of this image available (depricated?)
#     Defaults to undef
# [*forcheckout*] 
#   - Assign this image for checkout
#     Defaults to undef -> inherits defaults from vcl_image
# [*project*] 
#   - Project within which this image is available
#     Defaults to 'vcl'
# [*size*] 
#   - Size of this image
#     Defaults to 1500,
# [*architecture*] 
#   - Architecture this image targets
#     Defaults to 'x86_64'
# [*description*] 
#   - Description for this image
#     Defaults to undef
# [*usage*] 
#   - notes on how to use image displayed on Connect page
#     Defaults to undef
# [*deleted*] 
#   - Whether this image should be marked deleted
#     Defaults to false,
# [*url*] 
#   - URL from which to download the iso for this image
#     Defaults to undef
# [*filepath*] 
#   - File location of the iso for this image
# [*distro*] 
#   - OS distribution identifier of this image
#
define vclmgmt::baseimage(
  $ensure        = present,
  $prettyname, 
  $platform      = 'i386', 
  $os, 
  $minram        = 512,
  $minprocnumber = 1,
  $minprocspeed  = 1024,
  $minnetwork    = 100,
  $maxconcurrent = undef,
  $test          = undef,
  $forcheckout   = undef,
  $project       = 'vcl',
  $size          = 1500,
  $architecture  = 'x86_64',
  $description   = undef,
  $usage         = undef,
  $deleted       = false,
  $url           = undef,
  $filepath,
  $distro,
) {
  vcl_image { $name :
    ensure        => $ensure,
    prettyname    => $prettyname, 
    platform      => $platform, 
    os            => $os, 
    minram        => $minram,
    minprocnumber => $minprocnumber,
    minprocspeed  => $minprocspeed,
    minnetwork    => $minnetwork,
    maxconcurrent => $maxconcurrent,
    test          => $test,
    forcheckout   => $forcheckout,
    project       => $project,
    size          => $size,
    architecture  => $architecture,
    description   => $description,
    usage         => $usage,
    deleted       => $deleted,
  }
        
  xcat::image{ "${name}-img" :
    ensure   => $ensure,
    url      => $url,
    filepath => $filepath,
    distro   => $distro,
    arch     => $architecture,
  }
}
