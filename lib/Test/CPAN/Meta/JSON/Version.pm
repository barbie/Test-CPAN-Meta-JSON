package Test::CPAN::Meta::JSON::Version;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.14';

#----------------------------------------------------------------------------

=head1 NAME

Test::CPAN::Meta::JSON::Version - Validate CPAN META data against the specification

=head1 SYNOPSIS

  use Test::CPAN::Meta::JSON::Version;

=head1 DESCRIPTION

This module was written to ensure that a META.json file, provided with a
standard distribution uploaded to CPAN, meets the specifications that are
slowly being introduced to module uploads, via the use of
L<ExtUtils::MakeMaker>, L<Module::Build> and L<Module::Install>.

This module is meant to be used together with L<Test::CPAN::Meta::JSON>, however
the code is self contained enough that you can access it directly.

See L<CPAN::Meta> for further details of the CPAN Meta Specification.

=head1 ABSTRACT

Validation of META.json data against the CPAN Meta Specification.

=cut

#----------------------------------------------------------------------------

#############################################################################
#Specification Definitions                                                  #
#############################################################################

my $spec_error = "Missing validation action in specification. "
  . "Must be one of 'map', 'list', 'lazylist' or 'value'";

my %known_specs = (
    '1.4' => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
    '1.3' => 'http://module-build.sourceforge.net/META-spec-v1.3.html',
    '1.2' => 'http://module-build.sourceforge.net/META-spec-v1.2.html',
    '1.1' => 'http://module-build.sourceforge.net/META-spec-v1.1.html',
    '1.0' => 'http://module-build.sourceforge.net/META-spec-v1.0.html'
);
my %known_urls = map {$known_specs{$_} => $_} keys %known_specs;

my $module_map1 = { 'map' => { ':key' => { name => \&module, value => \&exversion } } };
my $module_map2 = { 'map' => { ':key' => { name => \&module, value => \&version   } } };
my $no_index_1_3 = {
    'map'       => { file       => { list => { value => \&string } },
                     directory  => { list => { value => \&string } },
                     'package'  => { list => { value => \&string } },
                     namespace  => { list => { value => \&string } },
    }
};
my $no_index_1_2 = {
    'map'       => { file       => { list => { value => \&string } },
                     dir        => { list => { value => \&string } },
                     'package'  => { list => { value => \&string } },
                     namespace  => { list => { value => \&string } },
    }
};
my $no_index_1_1 = {
    'map'       => { ':key'     => { name => \&keyword, list => { value => \&string } },
    }
};

my $prereq_map = {
    'map' => {
      ':key' => {
        name => \&phase,
        'map' => {
          ':key'  => {
            name => \&relation,
            %$module_map1
          }
        }
      }
    }
};

my %definitions = (
  '2' => {
    # REQUIRED
    'abstract'            => { mandatory => 1, value => \&string  },
    'author'              => { mandatory => 1, lazylist => { value => \&string } },
    'dynamic_config'      => { mandatory => 1, value => \&boolean },
    'generated_by'        => { mandatory => 1, value => \&string  },
    'license'             => { mandatory => 1, lazylist => { value => \&license } },
    'meta-spec' => {
      mandatory => 1,
      'map' => {
        version => { mandatory => 1, value => \&version},
        url     => { value => \&url }
      }
    },
    'name'                => { mandatory => 1, value => \&string  },
    'release_status'      => { mandatory => 1, value => \&release_status },
    'version'             => { mandatory => 1, value => \&version },

    # OPTIONAL
    'description' => { value => \&string },
    'keywords'    => { lazylist => { value => \&string } },
    'no_index'    => $no_index_1_3,
    'optional_features'   => {
      'map'       => {
        ':key' => {
          name  => \&identifier,
          'map' => {
            description => { value => \&string },
            prereqs     => $prereq_map,
          }
        }
      }
    },
    'prereqs' => $prereq_map,
    'provides'    => {
      'map'       => {
        ':key' => {
          name  => \&module,
          'map' => {
            file    => { mandatory => 1, value => \&file },
            version => { value => \&version } } } }
    },
    'resources'   => {
      'map'       => {
        license    => { lazylist => { value => \&url } },
        homepage   => { value => \&url },
        bugtracker => {
          'map' => {
            web     => { value => \&url },
            mailto  => { value => \&string},
          }},
        repository => {
          'map' => {
            web     => { value => \&url },
            url     => { value => \&url },
            type    => { value => \&string },
          }},
        ':key' => { value => \&string, name => \&custom_2 },
      }
    },

    # CUSTOM -- additional user defined key/value pairs
    # note we can only validate the key name, as the structure is user defined
    ':key'        => { name => \&custom_2, value => \&anything },
  },

'1.4' => {
  'meta-spec'           => { mandatory => 1, 'map' => { version => { mandatory => 1, value => \&version},
                                                        url     => { mandatory => 1, value => \&urlspec } } },

  'name'                => { mandatory => 1, value => \&string  },
  'version'             => { mandatory => 1, value => \&version },
  'abstract'            => { mandatory => 1, value => \&string  },
  'author'              => { mandatory => 1, list  => { value => \&string } },
  'license'             => { mandatory => 1, value => \&license },
  'generated_by'        => { mandatory => 1, value => \&string  },

  'distribution_type'   => { value => \&string  },
  'dynamic_config'      => { value => \&boolean },

  'requires'            => $module_map1,
  'recommends'          => $module_map1,
  'build_requires'      => $module_map1,
  'configure_requires'  => $module_map1,
  'conflicts'           => $module_map2,

  'optional_features'   => {
    'map'       => {
        ':key'  => { name => \&identifier,
            'map'   => { description        => { value => \&string },
                         requires_packages  => { value => \&string },
                         requires_os        => { value => \&string },
                         excludes_os        => { value => \&string },
                         requires           => $module_map1,
                         recommends         => $module_map1,
                         build_requires     => $module_map1,
                         conflicts          => $module_map2,
            }
        }
     }
  },

  'provides'    => {
    'map'       => { ':key' => { name  => \&module,
                                 'map' => { file    => { mandatory => 1, value => \&file },
                                            version => { value => \&version } } } }
  },

  'no_index'    => $no_index_1_3,
  'private'     => $no_index_1_3,

  'keywords'    => { list => { value => \&string } },

  'resources'   => {
    'map'       => { license    => { value => \&url },
                     homepage   => { value => \&url },
                     bugtracker => { value => \&url },
                     repository => { value => \&url },
                     ':key'     => { value => \&string, name => \&resource },
    }
  },

  # additional user defined key/value pairs
  # note we can only validate the key name, as the structure is user defined
  ':key'        => { name => \&keyword, value => \&anything },
},

'1.3' => {
  'meta-spec'           => { mandatory => 1, 'map' => { version => { mandatory => 1, value => \&version},
                                                        url     => { mandatory => 1, value => \&urlspec } } },

  'name'                => { mandatory => 1, value => \&string  },
  'version'             => { mandatory => 1, value => \&version },
  'abstract'            => { mandatory => 1, value => \&string  },
  'author'              => { mandatory => 1, list  => { value => \&string } },
  'license'             => { mandatory => 1, value => \&license },
  'generated_by'        => { mandatory => 1, value => \&string  },

  'distribution_type'   => { value => \&string  },
  'dynamic_config'      => { value => \&boolean },

  'requires'            => $module_map1,
  'recommends'          => $module_map1,
  'build_requires'      => $module_map1,
  'conflicts'           => $module_map2,

  'optional_features'   => {
    'map'       => {
        ':key'  => { name => \&identifier,
            'map'   => { description        => { value => \&string },
                         requires_packages  => { value => \&string },
                         requires_os        => { value => \&string },
                         excludes_os        => { value => \&string },
                         requires           => $module_map1,
                         recommends         => $module_map1,
                         build_requires     => $module_map1,
                         conflicts          => $module_map2,
            }
        }
     }
  },

  'provides'    => {
    'map'       => { ':key' => { name  => \&module,
                                 'map' => { file    => { mandatory => 1, value => \&file },
                                            version => { value => \&version } } } }
  },

  'no_index'    => $no_index_1_3,
  'private'     => $no_index_1_3,

  'keywords'    => { list => { value => \&string } },

  'resources'   => {
    'map'       => { license    => { value => \&url },
                     homepage   => { value => \&url },
                     bugtracker => { value => \&url },
                     repository => { value => \&url },
                     ':key'     => { value => \&string, name => \&resource },
    }
  },

  # additional user defined key/value pairs
  # note we can only validate the key name, as the structure is user defined
  ':key'        => { name => \&keyword, value => \&anything },
},

# v1.2 is misleading, it seems to assume that a number of fields where created
# within v1.1, when they were created within v1.2. This may have been an
# original mistake, and that a v1.1 was retro fitted into the timeline, when
# v1.2 was originally slated as v1.1. But I could be wrong ;)
'1.2' => {
  'meta-spec'           => { mandatory => 1, 'map' => { version => { mandatory => 1, value => \&version},
                                                        url     => { mandatory => 1, value => \&urlspec } } },

  'name'                => { mandatory => 1, value => \&string  },
  'version'             => { mandatory => 1, value => \&version },
  'license'             => { mandatory => 1, value => \&license },
  'generated_by'        => { mandatory => 1, value => \&string  },
  'author'              => { mandatory => 1, list => { value => \&string } },
  'abstract'            => { mandatory => 1, value => \&string  },

  'distribution_type'   => { value => \&string  },
  'dynamic_config'      => { value => \&boolean },

  'keywords'            => { list => { value => \&string } },

  'private'             => $no_index_1_2,
  '$no_index'           => $no_index_1_2,

  'requires'            => $module_map1,
  'recommends'          => $module_map1,
  'build_requires'      => $module_map1,
  'conflicts'           => $module_map2,

  'optional_features'   => {
    'map'       => {
        ':key'  => { name => \&identifier,
            'map'   => { description        => { value => \&string },
                         requires_packages  => { value => \&string },
                         requires_os        => { value => \&string },
                         excludes_os        => { value => \&string },
                         requires           => $module_map1,
                         recommends         => $module_map1,
                         build_requires     => $module_map1,
                         conflicts          => $module_map2,
            }
        }
     }
  },

  'provides'    => {
    'map'       => { ':key' => { name  => \&module,
                                 'map' => { file    => { mandatory => 1, value => \&file },
                                            version => { value => \&version } } } }
  },

  'resources'   => {
    'map'       => { license    => { value => \&url },
                     homepage   => { value => \&url },
                     bugtracker => { value => \&url },
                     repository => { value => \&url },
                     ':key'     => { value => \&string, name => \&resource },
    }
  },

  # additional user defined key/value pairs
  # note we can only validate the key name, as the structure is user defined
  ':key'        => { name => \&keyword, value => \&anything },
},

# note that the 1.1 spec doesn't specify optional or mandatory fields, what
# appears below is assumed from later specifications.
'1.1' => {
  'name'                => { mandatory => 1, value => \&string  },
  'version'             => { mandatory => 1, value => \&version },
  'license'             => { mandatory => 1, value => \&license },
  'license_uri'         => { mandatory => 0, value => \&url },
  'generated_by'        => { mandatory => 1, value => \&string  },

  'distribution_type'   => { value => \&string  },
  'dynamic_config'      => { value => \&boolean },

  'private'             => $no_index_1_1,

  'requires'            => $module_map1,
  'recommends'          => $module_map1,
  'build_requires'      => $module_map1,
  'conflicts'           => $module_map2,

  # additional user defined key/value pairs
  # note we can only validate the key name, as the structure is user defined
  ':key'        => { name => \&keyword, value => \&anything },
},

# note that the 1.0 spec doesn't specify optional or mandatory fields, what
# appears below is assumed from later specifications.
'1.0' => {
  'name'                => { mandatory => 1, value => \&string  },
  'version'             => { mandatory => 1, value => \&version },
  'license'             => { mandatory => 1, value => \&license },
  'generated_by'        => { mandatory => 1, value => \&string  },

  'distribution_type'   => { value => \&string  },
  'dynamic_config'      => { value => \&boolean },

  'requires'            => $module_map1,
  'recommends'          => $module_map1,
  'build_requires'      => $module_map1,
  'conflicts'           => $module_map2,

  # additional user defined key/value pairs
  # note we can only validate the key name, as the structure is user defined
  ':key'        => { name => \&keyword, value => \&anything },
},
);

#############################################################################
#Code                                                                       #
#############################################################################

=head1 CLASS CONSTRUCTOR

=over

=item * new( data => $data [, spec => $version] )

The constructor must be passed a valid data structure.

Optionally you may also provide a specification version. This version is then
use to ensure that the given data structure meets the respective
specification definition. If no version is provided the module will attempt to
deduce the appropriate specification version from the data structure itself.

=back

=cut

sub new {
    my ($class,%hash) = @_;

    # create an attributes hash
    my $atts = {
        'spec' => $hash{spec},
        'data' => $hash{data},
    };

    # create the object
    my $self = bless $atts, $class;
}

=head1 METHODS

=head2 Main Methods

=over

=item * parse()

Using the given data structure provided with the constructor, attempts to
parse and validate according to the appropriate specification definition.

Returns 1 if any errors found, otherwise returns 0.

=item * errors()

Returns a list of the errors found during parsing.

=back

=cut

sub parse {
    my $self = shift;
    my $data = $self->{data};

    unless($self->{spec}) {
        $self->{spec} = $data->{'meta-spec'} && $data->{'meta-spec'}{'version'} ? $data->{'meta-spec'}{'version'} : '2';
    }

    $self->check_map($definitions{$self->{spec}},$data);
    return defined $self->{errors} ? 1 : 0;
}

sub errors {
    my $self = shift;
    return ()   unless($self->{errors});
    return @{$self->{errors}};
}

=head2 Check Methods

=over

=item * check_map($spec,$data)

Checks whether a map (or hash) part of the data structure conforms to the
appropriate specification definition.

=item * check_lazylist($spec,$data)

If it's a string, make it into a list and check the list

=item * check_list($spec,$data)

Checks whether a list (or array) part of the data structure conforms to
the appropriate specification definition.

=back

=cut

sub check_map {
    my ($self,$spec,$data) = @_;

    if(ref($spec) ne 'HASH') {
        $self->_error( "Unknown META.yml specification, cannot validate." );
        return;
    }

    if(ref($data) ne 'HASH') {
        $self->_error( "Expected a map structure from data string or file." );
        return;
    }

    for my $key (keys %$spec) {
        next    unless($spec->{$key}->{mandatory});
        next    if(defined $data->{$key});
        push @{$self->{stack}}, $key;
        $self->_error( "Missing mandatory field, '$key'" );
        pop @{$self->{stack}};
    }

    for my $key (keys %$data) {
        push @{$self->{stack}}, $key;
        if($spec->{$key}) {
            if($spec->{$key}{value}) {
                $spec->{$key}{value}->($self,$key,$data->{$key});
            } elsif($spec->{$key}{'map'}) {
                $self->check_map($spec->{$key}{'map'},$data->{$key});
            } elsif($spec->{$key}{'list'}) {
                $self->check_list($spec->{$key}{'list'},$data->{$key});
            } elsif($spec->{$key}{'lazylist'}) {
                $self->check_lazylist($spec->{$key}{'lazylist'},$data->{$key});
            } else {
                $self->_error( "$spec_error for '$key'" );
            }

        } elsif ($spec->{':key'}) {
            $spec->{':key'}{name}->($self,$key,$key);
            if($spec->{':key'}{value}) {
                $spec->{':key'}{value}->($self,$key,$data->{$key});
            } elsif($spec->{':key'}{'map'}) {
                $self->check_map($spec->{':key'}{'map'},$data->{$key});
            } elsif($spec->{':key'}{'list'}) {
                $self->check_list($spec->{':key'}{'list'},$data->{$key});
            } elsif($spec->{':key'}{'lazylist'}) {
                $self->check_list($spec->{':key'}{'lazylist'},$data->{$key});
            } elsif(!$spec->{':key'}{name}) {
                $self->_error( "$spec_error for ':key'" );
            }

        } else {
            $self->_error( "Unknown key, '$key', found in map structure" );
        }
        pop @{$self->{stack}};
    }
}

sub check_lazylist {
    my ($self,$spec,$data) = @_;

    if ( defined $data && ! ref($data) ) {
        $data = [ $data ];
    }

    $self->check_list($spec,$data);
}

sub check_list {
    my ($self,$spec,$data) = @_;

    if(ref($data) ne 'ARRAY') {
        $self->_error( "Expected a list structure" );
        return;
    }

    if(defined $spec->{mandatory}) {
        if(!defined $data->[0]) {
            $self->_error( "Missing entries from mandatory list" );
        }
    }

    for my $value (@$data) {
        push @{$self->{stack}}, $value;
        if(defined $spec->{value}) {
            $spec->{value}->($self,'list',$value);
        } elsif(defined $spec->{'map'}) {
            $self->check_map($spec->{'map'},$value);
        } elsif(defined $spec->{'list'}) {
            $self->check_list($spec->{'list'},$value);
        } elsif(defined $spec->{'lazylist'}) {
            $self->check_lazylist($spec->{'lazylist'},$value);

        } elsif ($spec->{':key'}) {
            $self->check_map($spec,$value);

        } else {
            $self->_error( "$spec_error associated with '$self->{stack}[-2]'" );
        }
        pop @{$self->{stack}};
    }
}

=head2 Validator Methods

=over

=item * url($self,$key,$value)

Validates that a given value is in an acceptable URL format

=item * urlspec($self,$key,$value)

Validates that the URL to a META.yml specification is a known one.

=item * string_or_undef($self,$key,$value)

Validates that the value is either a string or an undef value. Bit of a
catchall function for parts of the data structure that are completely user
defined.

=item * string($self,$key,$value)

Validates that a string exists for the given key.

=item * file($self,$key,$value)

Validate that a file is passed for the given key. This may be made more
thorough in the future. For now it acts like \&string.

=item * exversion($self,$key,$value)

Validates a list of versions, e.g. '<= 5, >=2, ==3, !=4, >1, <6, 0'.

=item * version($self,$key,$value)

Validates a single version string. Versions of the type '5.8.8' and '0.00_00'
are both valid. A leading 'v' like 'v1.2.3' is also valid.

=item * boolean($self,$key,$value)

Validates for a boolean value. Currently these values are '1', '0', 'true',
'false', however the latter 2 may be removed.

=item * license($self,$key,$value)

Validates that a value is given for the license. Returns 1 if an known license
type, or 2 if a value is given but the license type is not a recommended one.

=item * resource($self,$key,$value)

Validates that the given key is in CamelCase, to indicate a user defined
keyword.

=item * keyword($self,$key,$value)

Validates that key is in an acceptable format for the META.yml specification,
i.e. any in the character class [-_a-z].

For user defined keys, although not explicitly stated in the specifications
(v1.0 - v1.4), the convention is to precede the key with a pattern matching
qr{\Ax_}i. Following this any character from the character class [-_a-zA-Z]
can be used. This clarification has been added to v2.0 of the specification.

=item * identifier($self,$key,$value)

Validates that key is in an acceptable format for the META.yml specification,
for an identifier, i.e. any that matches the regular expression
qr/[a-z][a-z_]/i.

=item * module($self,$key,$value)

Validates that a given key is in an acceptable module name format, e.g.
'Test::CPAN::Meta::JSON::Version'.

=item * release_status($self,$key,$value)

Validates that the value for 'release_status' is set appropriately for one of
'stable', 'testing' or 'unstable'.

=item * custom_1($self,$key,$value)

Validates custom keys based on camelcase only.

=item * custom_2($self,$key,$value)

Validates custom keys based on user defined (i.e. /^[xX]_/) only.

=item * phase($self,$key,$value)

Validates for a legal phase of a pre-requisite map.

=item * relation($self,$key,$value)

Validates for a legal relation, within a phase, of a pre-requisite map.

=item * anything($self,$key,$value)

Usually reserved for user defined structures, allowing them to be considered
valid without a need for a specification definition for the structure.

=back

=cut

sub _uri_split {
     return $_[0] =~ m,(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?,;
}

sub url {
    my ($self,$key,$value) = @_;
    if($value) {
        my ($scheme, $auth, $path, $query, $frag) = _uri_split($value);

        unless ( $scheme ) {
            $self->_error( "'$value' for '$key' does not have a URL scheme" );
            return 0;
        }
        unless ( $auth ) {
            $self->_error(  "'$value' for '$key' does not have a URL authority" );
            return 0;
        }
        return 1;
    } else {
        $value = '<undef>';
    }
    $self->_error( "'$value' for '$key' is not a valid URL." );
    return 0;
}

sub urlspec {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1    if($value && $known_specs{$self->{spec}} eq $value);
        if($value && $known_urls{$value}) {
            $self->_error( 'META.yml specification URL does not match version' );
            return 0;
        }
    }
    $self->_error( 'Unknown META.yml specification' );
    return 0;
}

sub string {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1    if($value || $value =~ /^0$/);
    }
    $self->_error( "value is an undefined string" );
    return 0;
}

sub string_or_undef {
    my ($self,$key,$value) = @_;
    return 1    unless(defined $value);
    return 1    if($value || $value =~ /^0$/);
    $self->_error( "No string defined for '$key'" );
    return 0;
}

sub file {
    my ($self,$key,$value) = @_;
    return 1    if(defined $value);
    $self->_error( "No file defined for '$key'" );
    return 0;
}

sub exversion {
    my ($self,$key,$value) = @_;
    if(defined $value && ($value || $value =~ /0/)) {
        my $pass = 1;
        for(split(",",$value)) { $self->version($key,$_) or ($pass = 0); }
        return $pass;
    }
    $value = '<undef>'  unless(defined $value);
    $self->_error( "'$value' for '$key' is not a valid version." );
    return 0;
}

sub version {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 0    unless($value || $value =~ /0/);
        return 1    if($value =~ /^\s*((<|<=|>=|>|!=|==)\s*)?v?\d+((\.\d+((_|\.)\d+)?)?)/);
    } else {
        $value = '<undef>';
    }
    $self->_error( "'$value' for '$key' is not a valid version." );
    return 0;
}

sub boolean {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        return 1    if($value =~ /^(0|1|true|false)$/);
    } else {
        $value = '<undef>';
    }
    $self->_error( "'$value' for '$key' is not a boolean value." );
    return 0;
}

my %v1_licenses = (
    'perl'         => 'http://dev.perl.org/licenses/',
    'gpl'          => 'http://www.opensource.org/licenses/gpl-license.php',
    'apache'       => 'http://apache.org/licenses/LICENSE-2.0',
    'artistic'     => 'http://opensource.org/licenses/artistic-license.php',
    'artistic2'    => 'http://opensource.org/licenses/artistic-license-2.0.php',
    'artistic-2.0' => 'http://opensource.org/licenses/artistic-license-2.0.php',
    'lgpl'         => 'http://www.opensource.org/licenses/lgpl-license.phpt',
    'bsd'          => 'http://www.opensource.org/licenses/bsd-license.php',
    'gpl'          => 'http://www.opensource.org/licenses/gpl-license.php',
    'mit'          => 'http://opensource.org/licenses/mit-license.php',
    'mozilla'      => 'http://opensource.org/licenses/mozilla1.1.php',
    'open_source'  => undef,
    'unrestricted' => undef,
    'restrictive'  => undef,
    'unknown'      => undef,
);

my %v2_licenses = map { $_ => 1 } qw(
  agpl_3
  apache_1_1
  apache_2_0
  artistic_1
  artistic_2
  bsd
  freebsd
  gfdl_1_2
  gfdl_1_3
  gpl_1
  gpl_2
  gpl_3
  lgpl_2_1
  lgpl_3_0
  mit
  mozilla_1_0
  mozilla_1_1
  openssl
  perl_5
  qpl_1_0
  ssleay
  sun
  zlib
  open_source
  restricted
  unrestricted
  unknown
);

sub license {
    my ($self,$key,$value) = @_;
    my $licenses = $self->{spec} < 2 ? \%v1_licenses : \%v2_licenses;
    if(defined $value) {
        return 1    if($value && exists $licenses->{$value});

        # v1 specs caused problems for some with this field,
        # so this test is relaxed for v1 tests only.
        return 2    if($value && $self->{spec} < 2);
    } else {
        $value = '<undef>';
    }
    $self->_error( "License '$value' is invalid" );
    return 0;
}

sub resource {
    my ($self,$key) = @_;
    if(defined $key) {
        # a valid user defined key should be alphabetic
        # and contain at least one capital case letter.
        return 1    if($key && $key =~ /^[a-z]+$/i && $key =~ /[A-Z]/);
    } else {
        $key = '<undef>';
    }
    $self->_error( "Resource '$key' must be in CamelCase." );
    return 0;
}

sub keyword {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1    if($key && $key =~ /^([a-z][-_a-z]*)$/);    # spec defined
        return 1    if($key && $key =~ /^x_([a-z][-_a-z]*)$/i); # user defined
    } else {
        $key = '<undef>';
    }
    $self->_error( "Key '$key' is not a legal keyword." );
    return 0;
}

sub identifier {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1    if($key && $key =~ /^([a-z][_a-z]+)$/i);    # spec 2.0 defined
    } else {
        $key = '<undef>';
    }
    $self->_error( "Key '$key' is not a legal identifier." );
    return 0;
}

sub module {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1    if($key && $key =~ /^[A-Za-z0-9_]+(::[A-Za-z0-9_]+)*$/);
    } else {
        $key = '<undef>';
    }
    $self->_error( "Key '$key' is not a legal module name." );
    return 0;
}

sub release_status {
    my ($self,$key,$value) = @_;
    if(defined $value) {
        my $version = $self->{data}{version} || '';
        if ( $version =~ /_/ ) {
            return 1 if ( $value =~ /\A(?:testing|unstable)\z/ );
            $self->_error( "'$value' for '$key' is invalid for version '$version'" );
        } else {
            return 1 if ( $value =~ /\A(?:stable|testing|unstable)\z/ );
            $self->_error( "'$value' for '$key' is invalid" );
        }
    } else {
        $self->_error( "'$key' is not defined" );
    }
    return 0;
}

sub custom_1 {
    my ($self,$key) = @_;
    if(defined $key) {
        # a valid user defined key should be alphabetic
        # and contain at least one capital case letter.
        return 1    if($key && $key =~ /^[a-z]+$/i && $key =~ /[A-Z]/);
    } else {
        $key = '<undef>';
    }
    $self->_error( "Custom resource '$key' must be in CamelCase." );
    return 0;
}

sub custom_2 {
    my ($self,$key) = @_;
    if(defined $key) {
        # a valid user defined key should be alphabetic
        # and begin with x_ or X_
        return 1    if($key && $key =~ /^x_([a-z][-_a-z]*)$/i); # user defined
    } else {
        $key = '<undef>';
    }
    $self->_error( "Custom resource '$key' must begin with 'x_' or 'X_'." );
    return 0;
}

my @valid_phases = qw/ configure build test runtime develop /;
sub phase {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1 if( length $key && grep { $key eq $_ } @valid_phases );
    } else {
        $key = '<undef>';
    }
    $self->_error( "Key '$key' is not a legal phase." );
    return 0;
}

my @valid_relations = qw/ requires recommends suggests conflicts /;
sub relation {
    my ($self,$key) = @_;
    if(defined $key) {
        return 1 if( length $key && grep { $key eq $_ } @valid_relations );
    } else {
        $key = '<undef>';
    }
    $self->_error( "Key '$key' is not a legal prereq relationship." );
    return 0;
}

sub anything { return 1 }

sub _error {
    my $self = shift;
    my $mess = shift;

    $mess .= ' ('.join(' -> ',@{$self->{stack}}).')'  if($self->{stack});
    $mess .= " [Validation: $self->{spec}]";

    push @{$self->{errors}}, $mess;
}

q( Currently Listening To: Rainbow - "I Surrender" from 'Outrage - Live in London 1981');

__END__

#----------------------------------------------------------------------------

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=Test-CPAN-Meta-JSON).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

Barbie, <barbie@cpan.org>
for Miss Barbell Productions, L<http://www.missbarbell.co.uk>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2012 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
