package Dist::Zilla::Plugin::ConvertYAMLChanges;

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

# VERSION

use Moose;
#use experimental 'smartmatch';
use namespace::autoclean;

use CPAN::Changes;
use File::Slurp;
use YAML::XS;

with (
    'Dist::Zilla::Role::FileMunger',
);

sub munge_file {
    my ($self, $file) = @_;

    my $fname = $file->name;

    unless ($fname =~ m!Changes!) {
        #$self->log_debug("Skipping: '$fname' not Changes file");
        return;
    }

    #$log->tracef("Processing file %s ...", $fname);
    $self->log("Processing file $fname ...");

    #use Data::Dump; dd $self->zilla->{distmeta};
    my $changes = CPAN::Changes->new(
        preamble => "Revision history for " . $self->zilla->{distmeta}{name},
    );
    for my $yaml (Load(~~read_file($fname))) {
        next unless ref($yaml) eq 'HASH' && defined $yaml->{version};

        my $chs0 = $yaml->{changes};
        my $chs;

        # try to guess the format of changes:
        if (ref($chs0) eq 'HASH') {
            # already categorized? pass unchanged
            $chs = $chs0;
        } elsif (ref($chs0) eq 'ARRAY') {
            for my $ch (@$chs0) {
                if (ref($ch) eq 'HASH') {
                    for (keys %$ch) {
                        $chs->{$_} //= [];
                        push @{ $chs->{$_} }, $ch->{$_};
                    }
                } elsif (!ref($ch)) {
                    $chs->{''} //= [];
                    push @{ $chs->{''} }, $ch;
                } else {
                    die "Sorry, can't figure out format of change $ch for $yaml->{version}";
                }
            }
        } else {
            die "Sorry, can't figure out format of changes for $yaml->{version}";
        }
        #use Data::Dump; dd $chs;
        $yaml->{changes} = $chs;
        $changes->add_release($yaml);
    }

    $self->log("Converted YAML to CPAN::Changes format: $fname");
    $file->content($changes->serialize);

    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Convert Changes from YAML to CPAN::Changes format

=for Pod::Coverage ^(munge_file)$

=head1 SYNOPSIS

In dist.ini:

 [ConvertYAMLChanges]


=head1 DESCRIPTION

This plugin converts Changes from YAML format (like that found in C<Mo> or other
INGY's distributions) to CPAN::Changes format. First written to aid Neil Bowers'
quest[1].

[1] http://blogs.perl.org/users/neilb/2013/10/fancy-writing-a-distzilla-plugin.html

=cut
