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

    #use Data::Dump; dd $self;
    #use Data::Dump; dd $self->zilla;
    my $changes = CPAN::Changes->new(
        preamble => "Revision history for ", $self->{distmeta}{name},
    );
    for my $yaml (Load(~~read_file($fname))) {
        next unless ref($yaml) eq 'HASH' && defined $yaml->{version};
        # group by category of changes
        if (ref($yaml->{changes}) eq 'ARRAY') {
            $yaml->{changes} = { '' => $yaml->{changes} };
        }
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
