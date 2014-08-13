use strict;
use warnings;
package Bot::Backbone::Service::Fact;

# ABSTRACT: Various Bot::Backbone services for tracking facts

=head1 SYNOPSIS

    service keyword => (
        service => 'Fact::Keyword',
    );

    service predicate => (
        service => 'Fact::Predicate',
    );

=head1 DESCRIPTION

This is a collection of modules designed around the theme of remember
and reporting facts. These modules can be useful for letting your bot provide
useful information in the chat or for just adding a fun things for the bot to
do.

Here is a summary of the included services:

=over

=item *

L<Bot::Backbone::Service::Fact::Keyword>. Once running, this service keeps a database of keywords that have a random chance of triggering a response. This may be useful for creating help triggers to help explain certain terminology, but only being as noisy as you want it to be. It can also be used to have the bot scream hysterically whenever it's name is mentioned.

=item *

L<Bot::Backbone::Service::Fact::Predicate>. This tracks a set of facts in predicate nominative form (i.e., statements of equivalence, e.g., "The sky is blue."). Then, whenever a user asks about that predicate (e.g., "What is the sky?"), the bot can respond with the full statement of the fact.

=back

=cut

1;
