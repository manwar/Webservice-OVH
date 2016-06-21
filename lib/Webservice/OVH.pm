package Webservice::OVH;

=encoding utf-8

=head1 NAME

Webservice::OVH  - A perl representation of the ovh-api

=head1 SYNOPSIS

    use Webservice::OVH;

    my $ovh = Webservice::OVH->new("credentials.json");

    my $ovh = Webservice::OVH->new(application_key => $key, application_secret => $secret, consumer_key => $token);

    my $services = $ovh->domain->services;

    foreach my $service (@$services) {
    
        my $last_update = $service->last_update;
        print $last_update->datetime;
    }

=head1 DESCRIPTION

This module reflects the path structure of the ovh web-api.
This is the base object from where all api calls originate.

This module uses the perl api module provided by ovh.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.1;

# api module provided by ovh
use OvhApi;

# sub-modules
use Webservice::OVH::Domain;
use Webservice::OVH::Me;
use Webservice::OVH::Order;
use Webservice::OVH::Email;

# other requirements
use JSON;
use File::Slurp qw(read_file);

=head2 new_from_json

Creates an api Object based on credentials in a json File

=over

=item * Parameter: $file_json - dir to json file

=item * Return: L<Webservice::OVH>

=item * Synopsis: Webservice::OVH->new_from_json("path/file");

=back

=over 2

=item * application_key      is generated when creating an application via ovh web interface

=item * application_secret   is generated when creating an application via ovh web interface

=item * consumer_key         must be requested through ovh authentification

=item * timeout              timeout in milliseconds, warning some request may take a while

=back

=cut

sub new_from_json {

    my ( $class, $file_json ) = @_;

    # slurp file
    my $json = read_file $file_json, { binmode => ':utf8' };

    # decode json
    my $Json = JSON->new->allow_nonref;
    my $data = $Json->decode($json);

    # check for missing parameters in the json file
    my @keys = qw{ application_key application_secret consumer_key };
    if ( my @missing_parameters = grep { not $data->{$_} } @keys ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $self = bless {}, $class;

    # Create internal objects to mirror the web api of ovh
    my $api_wrapper = OvhApi->new( 'type' => "https://eu.api.ovh.com/1.0", applicationKey => $data->{application_key}, applicationSecret => $data->{application_secret}, consumerKey => $data->{consumer_key} );
    my $domain = Webservice::OVH::Domain->_new( $api_wrapper, $self );
    my $me = Webservice::OVH::Me->_new( $api_wrapper, $self );
    my $order = Webservice::OVH::Order->_new( $api_wrapper, $self );
    my $email = Webservice::OVH::Email->_new( $api_wrapper, $self );

    # Timeout can be also set in the json file
    OvhApi->setRequestTimeout( timeout => $data->{timeout} || 120 );

    # Setting private variables
    $self->{_domain}      = $domain;
    $self->{_me}          = $me;
    $self->{_order}       = $order;
    $self->{_api_wrapper} = $api_wrapper;
    $self->{_email}       = $email;

    return $self;
}

=head2 new

Create the api object. Credentials are given directly via %params
Credentials can be generated via ovh web interface and ovh authentification

=over

=item * Parameter: %params - application_key => value, application_secret => value, consumer_key => value

=item * Return: L<Webservice::OVH>

=item * Synopsis: Webservice::OVH->new(application_key => $key, application_secret => $secret, consumer_key => $token);

=back

=cut

sub new {

    my ( $class, %params ) = @_;

    my @keys = qw{ application_key application_secret consumer_key };

    if ( my @missing_parameters = grep { not $params{$_} } @keys ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $self = bless {}, $class;

    my $api_wrapper = OvhApi->new( 'type' => "https://eu.api.ovh.com/1.0", applicationKey => $params{application_key}, applicationSecret => $params{application_secret}, consumerKey => $params{consumer_key} );
    my $domain = Webservice::OVH::Domain->_new( $api_wrapper, $self );
    my $me = Webservice::OVH::Me->_new( $api_wrapper, $self );
    my $order = Webservice::OVH::Order->_new( $api_wrapper, $self );

    OvhApi->setRequestTimeout( timeout => $params{timeout} || 120 );

    $self->{_domain}      = $domain;
    $self->{_me}          = $me;
    $self->{_order}       = $order;
    $self->{_api_wrapper} = $api_wrapper;

    return $self;
}

=head2 set_timeout

Sets the timeout of the underlying LWP::Agent

=over

=item * Parameter: timeout - in milliseconds default 120

=item * Synopsis: Webservice::OVH->set_timeout(120);

=back

=cut

sub set_timeout {

    my ( $class, $timeout ) = @_;

    OvhApi->setRequestTimeout( timeout => $timeout );
}

=head2 domain

Main access to all /domain/ api methods 

=over

=item * Return: L<Webservice::OVH::Domain>

=item * Synopsis: $ovh->domain;

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

=head2 me

Main access to all /me/ api methods 

=over

=item * Return: L<Webservice::OVH::Me>

=item * Synopsis: $ovh->me;

=back

=cut

sub me {

    my ($self) = @_;

    return $self->{_me};
}

=head2 order

Main access to all /order/ api methods 

=over

=item * Return: L<Webservice::OVH::Order>

=item * Synopsis: $ovh->order;

=back

=cut

sub order {

    my ($self) = @_;

    return $self->{_order};
}

=head2 email

Main access to all /email/ api methods 

=over

=item * Return: L<Webservice::OVH::Email>

=item * Synopsis: $ovh->email;

=back

=cut

sub email {

    my ($self) = @_;

    return $self->{_email};
}

=head1 AUTHOR

Patrick Jendral

=head1 COPYRIGHT AND LICENSE

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
