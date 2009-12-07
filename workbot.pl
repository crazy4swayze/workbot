#!/home/associat/g/goldfish/local/bin/perl

package Workbot;
use Moses;
use Carp qw(carp);
use namespace::autoclean;
use feature 'switch';

owner    'goldfish!goldfish@Redbrick.dcu.ie';
nickname 'morry';
server   'irc.redbrick.dcu.ie';
channels '#moses';

has admins => (
    isa => 'HashRef',
    is  => 'ro',
    traits => [qw(Hash)],
    default => sub { {} },
    handles => {
        get_admin     => 'get',
        _set_admin    => 'set',
        is_admin      => 'exists',
        has_no_admins => 'is_empty',
        del_admin     => 'delete',
        _dump_admins  => 'keys',
    }
);

sub set_admin {
    my $self = shift;
    my ($admin_ref) = @_;
    my ($admin_key, $admin_val) = each %$admin_ref;
    if ($admin_key !~ /^[^!]+![^@]+\@([^.]+\.)+[^.]+$/){ 
        carp "$admin_key is not a valid key";
        return
    }
    $self->_set_admin($admin_key => $admin_val)
}

sub dump_admins {
    my $self = shift;
    $self->has_no_admins ? 'no admins.' : $self->_dump_admins
}

event irc_bot_addressed => sub {
    my ($bot, $nickstr, $channel, $msg) = @_[OBJECT, ARG0, ARG1, ARG2];
    my ($nick, $ident, $host) = parse_user($nickstr);
    my ($cmd, @args) = split ' ', $msg;

    given ($cmd) {
        when ($_ eq 'add' or $_ eq 'del') {
            break unless $bot->default_owner eq $nickstr;
            my $nicklist = $bot->irc->{STATE}{Nicks};
            foreach my $arg (@args) {
                foreach (keys %$nicklist) {
                    my $user = $nicklist->{$_};
# TODO : better variable name than $user
                    if ($user->{Nick} eq $arg) {
                        my $admin = $user->{Nick} . '!' . $user->{User} . '@' . $user->{Host};
# TODO : better variable name than $key
                        $cmd eq 'add' 
                            ? $bot->set_admin({$admin => 1})
                            : $bot->del_admin($admin);
                        last
                    }
                }
            }
        }
        when ($_ eq 'dump') {
            break unless $bot->default_owner eq $nickstr;
            $bot->privmsg($channel => "$nick: " . $bot->dump_admins)
        }
    }
};

__PACKAGE__->run unless caller;
