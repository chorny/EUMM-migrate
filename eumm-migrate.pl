#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

#License: GPL (may change in the future)

$INC{'ExtUtils/MakeMaker.pm'}=1;

package #hide from PAUSE
 ExtUtils::MakeMaker;
our $VERSION=6.54;

use Data::Dumper;

#our $writefile_data;
sub WriteMakefile {
  my %params=@_;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  print "License not specified\n" if not exists $params{LICENSE};
  if (exists $params{VERSION_FROM} and exists $params{ABSTRACT_FROM} and
   $params{VERSION_FROM} ne $params{ABSTRACT_FROM}) {
    die "VERSION_FROM can be separate from ABSTRACT_FROM in Module::Build";
  }
  my %transition=qw/
NAME	module_name
VERSION_FROM	dist_version_from
PREREQ_PM	requires
INSTALLDIRS	installdirs
EXE_FILES	script_files
PL_FILES	-
LICENSE	license
BUILD_REQUIRES	build_requires
META_MERGE	meta_merge
AUTHOR	dist_author
ABSTRACT_FROM	-
/;
  my %result;
  while (my($key,$val)=each %params) {
    next if $key eq 'MIN_PERL_VERSION';
    die "Unknown key '$key' in WriteMakefile call" unless exists $transition{$key};
    next if $transition{$key} eq '-';
    $result{$transition{$key}}=$val;
  }
  if (exists $params{'MIN_PERL_VERSION'}) {
    $result{requires}{perl}=$params{'MIN_PERL_VERSION'};
  }
  #print "Writing 
  open my $out,'>','Build.PL';
  my $str;
  #print $out Data::Dumper->Dump([\%result], ['my $build = Module::CPANTS::MyBuild->new(']);
  #print $out dump(\%result);
  { local $Data::Dumper::Indent =1;local $Data::Dumper::Terse=1;
    $str=Data::Dumper->Dump([\%result], []);
    $str=~s/^\{[\x0A\x0D]+//s;
    $str=~s/\}[\x0A\x0D]+\s*$//s;
  }
  print $out <<'EOT';
use strict;
use Module::Build;

my $build = Module::Build->new(
EOT
  print $out $str;
  print $out <<'EOT';
);

$build->create_build_script();
EOT

}

package main;
*WriteMakefile=*ExtUtils::MakeMaker::WriteMakefile;
do './Makefile.PL';
die if $@;
