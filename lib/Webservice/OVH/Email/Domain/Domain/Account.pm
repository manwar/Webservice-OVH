package Webservice::OVH::Email::Domain::Domain::Account;

=encoding utf-8

=head1 NAME

Webservice::OVH::Email::Domain::Domain::Account

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $email_domain = $ovh->email->domain->domain('testdomain.de');
    
    my $account = $email_domain->new_account( account_name => 'testaccount', password => $password, description => 'a test account', size => 50000000 );

=head1 DESCRIPTION

Provides access to email accounts.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.1;

=head2 _new_existing

Internal Method to create an Account object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $domain - parent domain Objekt, $account_name => unique name

=item * Return: L<Webservice::OVH::Email::Domain::Domain::Account>

=item * Synopsis: Webservice::OVH::Email::Domain::Domain::Account->_new_existing($ovh_api_wrapper, $domain, $account_name, $module);

=back

=cut

sub _new_existing {

    my ( $class, $api_wrapper, $domain, $account_name, $module ) = @_;
    die "Missing account_name" unless $account_name;
    $account_name = lc $account_name;

    my $domain_name = $domain->name;
    my $response = $api_wrapper->rawCall( method => 'get', path => "/email/domain/$domain_name/account/$account_name", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _name => $account_name, _properties => $porperties, _domain => $domain }, $class;

        return $self;
    } else {

        return undef;
    }
}

=head2 _new

Internal Method to create the Account object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $domain - parent domain, %params - key => value

=item * Return: L<Webservice::OVH::Email::Domain::Domain::Account>

=item * Synopsis: Webservice::OVH::Email::Domain::Domain::Account->_new($ovh_api_wrapper, $domain, $module, account_name => $account_name, password => $password, description => $description, size => $size  );

=back

=cut

sub _new {

    my ( $class, $api_wrapper, $domain, $module, %params ) = @_;

    my @keys_needed = qw{ account_name password };

    die "Missing domain" unless $domain;

    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $domain_name = $domain->name;
    my $body        = {};
    $body->{accountName} = $params{account_name};
    $body->{password}    = $params{password};
    $body->{description} = $params{description} if exists $params{description};
    $body->{size}        = $params{size} if exists $params{size};
    my $response = $api_wrapper->rawCall( method => 'post', path => "/email/domain/$domain_name/account", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $properties = $response->content;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _name => $params{account_name}, _properties => $properties, _domain => $domain }, $class;

    return $self;

}

=head2 is_valid

When this account is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $account->is_valid;

=back

=cut

sub is_valid {

    my ($self) = @_;

    return $self->{_valid};
}

=head2 _is_valid

Intern method to check validity.
Difference is that this method carps an error.

=over

=item * Return: VALUE

=item * Synopsis: $account->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    my $account_name = $self->name;
    carp "Account $account_name is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 name

Unique identifier.

=over

=item * Return: VALUE

=item * Synopsis: my $name = $account->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_name};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $account->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $response     = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account/$account_name", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};

}

=head2 is_blocked

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $is_blocked = $account->is_blocked;

=back

=cut

sub is_blocked {

    my ($self) = @_;

    return $self->{_properties}->{isBlocked} ? 1 : 0;

}

=head2 email

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $email = $account->email;

=back

=cut

sub email {

    my ($self) = @_;

    return $self->{_properties}->{email};

}

=head2 domain

Returns the email-domain this account is attached to. 

=over

=item * Return: L<Webservice::Email::Domain::Domain>

=item * Synopsis: my $email_domain = $account->domain;

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

=head2 description

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $description = $account->description;

=back

=cut

sub description {

    my ($self) = @_;

    return $self->{_properties}->{description};
}

=head2 size

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $size = $account->size;

=back

=cut

sub size {

    my ($self) = @_;

    return $self->{_properties}->{size};
}

=head2 change

Changes the account

=over

=item * Parameter: %params - key => value description size

=item * Synopsis: $account->change(description => 'authors account', size => 2000000 );

=back

=cut

sub change {

    my ( $self, %params ) = @_;

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $body         = {};
    $body->{description} = $params{description} if exists $params{description};
    $body->{size}        = $params{size}        if exists $params{size};
    my $response = $api->rawCall( method => 'put', path => "/email/domain/$domain_name/account/$account_name", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    $self->properties;

}

=head2 delete

Deletes the account api sided and sets this object invalid.

=over

=item * Synopsis: $account->delete;

=back

=cut

sub delete {

    my ( $self, %params ) = @_;

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $response     = $api->rawCall( method => 'delete', path => "/email/domain/$domain_name/account/$account_name", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

=head2 delete

Deletes the account api sided and sets this object invalid.

=over

=item * Parameter: $password - new password

=item * Synopsis: $account->change_password($password);

=back

=cut

sub change_password {

    my ( $self, $password ) = @_;

    return "Password too long"  if length $password > 30;
    return "Password too short" if length $password < 9;
    return "No '´' allowed"    if index( $password, '´' );

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $body         = { password => $password };
    my $response     = $api->rawCall( method => 'post', path => "/email/domain/$domain_name/account/$account_name/changePassword", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

}

=head2 usage

Deletes the account api sided and sets this object invalid.

=over

=item * Return: HASH

=item * Synopsis: $account->change_password($password);

=back

=cut

sub usage {

    my ($self) = @_;

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $response     = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account/$account_name/usage", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;

}

1;
