#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

#License: GPL (may change in the future)

$INC{'ExtUtils/MakeMaker.pm'}=1;

package #hide from PAUSE
 ExtUtils::MakeMaker;
our $VERSION=6.54;
use Exporter;
our @ISA=qw/Exporter/;
our @EXPORT=qw/prompt WriteMakefile/;
#our @EXPORT_OK=qw/prompt WriteMakefile/;

use Data::Dumper;
use File::Slurp;

my @prompts;
sub prompt ($;$) {  ## no critic
    my($mess, $def) = @_;
    push @prompts,[$mess, $def];
}


#our $writefile_data;
sub WriteMakefile {
  my %params=@_;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  #print "License not specified\n" if not exists $params{LICENSE};
  if (exists $params{VERSION_FROM} and exists $params{ABSTRACT_FROM} and
   $params{VERSION_FROM} ne $params{ABSTRACT_FROM}) {
    die "VERSION_FROM can't be different from ABSTRACT_FROM in Module::Build";
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
ABSTRACT	dist_abstract
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
  if (!exists $params{'META_MERGE'}{resources}{repository}) {
    require Module::Install::Repository;
    my $repo = Module::Install::Repository::_find_repo(\&Module::Install::Repository::_execute);
    if ($repo and $repo=~m#://#) {
      print "Repository found: $repo\n";
      eval {
        require NGP;
        $repo=NGP::github_parent($repo);
  
      };
      $result{'meta_merge'}{resources}{repository}=$repo;
    }
  }
  require Module::Install::Metadata;
  if (exists $params{'VERSION_FROM'}) {
    my $main_file_content=eval { read_file($params{'VERSION_FROM'}) };
    if (! exists($result{requires}{perl})) {
      my $version=Module::Install::Metadata::_extract_perl_version($main_file_content);
      if ($version) {
        $result{requires}{perl}=$version;
      }
    }
    if (! exists($result{license})) {
        my $l=Module::Install::Metadata::_extract_license($main_file_content);
        if ($l) {
          $result{license}=$l;
        }
    }
  }
  if (! exists($result{requires}{perl})) {
    my $makefilepl_content=eval { read_file('Makefile.PL') };
    my $version=Module::Install::Metadata::_extract_perl_version($makefilepl_content);
    if ($version) {
      $result{requires}{perl}=$version;
    }
  }
  #print "Writing 
  open my $out,'>','Build.PL';
  my $prompts_str='';
  if (@prompts) {
    $prompts_str.="die 'please write prompt handling code';\n";
    foreach my $p (@prompts) {
      my($mess, $def) = @$p;
      $prompts_str.="Module::Build->prompt(q{$mess},q{$def});\n";
    }
  }
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
EOT
print $out $prompts_str;
  print $out <<'EOT';
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
