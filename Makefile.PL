require 5.008;
use strict;
use warnings;
use ExtUtils::Depends;
use Data::Dumper qw(Dumper);
use ExtUtils::MakeMaker;
use IO::All;
use File::Spec;
use ExtUtils::PkgConfig;

my $version = '0.02';

my %gimpcfg = ExtUtils::PkgConfig->find("gimp-2.0");
my $gimppath = File::Spec->catdir(ExtUtils::PkgConfig->variable("gimp-2.0", "exec_prefix"), "bin");
my $gimptool = File::Spec->catfile($gimppath, "gimptool-2.0");
my ($plugindir, $pluginlibs) = split /\n/, `$gimptool --gimpplugindir --libs`;

my $gimpbinname = ExtUtils::PkgConfig->modversion("gimp-2.0");
$gimpbinname =~ s/^(\d\.\d).*/$1/; # strip off minor versions
die "Need GIMP version at least 2.8.0\n" unless $gimpbinname >= 2.8;

my %cfg = (
  gimp => File::Spec->catfile($gimppath, "gimp-" . $gimpbinname),
  gimptool => $gimptool,
  gimpplugindir => File::Spec->catdir($plugindir, "plug-ins"),
);

my $shortbase = "Alien/Gimp.pm";
my $basename = "lib/$shortbase";
my $cfg = io("$basename.in")->all or die "$basename.in: $!\n";
$cfg =~ s/#CFG#/Data::Dumper->Dump([\%cfg], ['*config'])/e;
$cfg =~ s/#VERSION#/$version/;
io($basename)->print($cfg) or die "$basename: $!\n";

my $pkg = ExtUtils::Depends->new('Alien::Gimp');
$pkg->set_inc($gimpcfg{"cflags"});
$pkg->set_libs($pluginlibs);
$pkg->add_pm(map { ("lib/$_" => "\$(INST_ARCHLIB)/$_") } $shortbase);
$pkg->save_config('lib/Alien/GimpIFiles.pm');

WriteMakefile(
  NAME	=> 'Alien::Gimp',
  VERSION => $version,
  MIN_PERL_VERSION => '5.014001',
  PREREQ_PM	=> {
    'IO::All'		=> 0,
    'ExtUtils::Depends'	=> '0.402',
#    'ExtUtils::PkgConfig'	=> 0,
  },
  TEST_REQUIRES => {
    'Inline'	=> '0.78',
    'Inline::C'	=> '0.67',
    'Test::More' => '0.88',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    provides => {
      'Alien::Gimp' => {
	file => 'META.json',
	version => $version,
      },
    },
    resources => {
      repository => {
	type => 'git',
	url => 'git://github.com/mohawk2/Alien-Gimp',
	web => 'https://github.com/mohawk2/Alien-Gimp',
      },
    },
  },
  clean	=> { FILES => 'lib/Alien/GimpIFiles.pm' },
  $pkg->get_makefile_vars,
);
