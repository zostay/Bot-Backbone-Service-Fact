package Bot::Backbone::Service::Fact::Predicate;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
    Bot::Backbone::Service::Role::Storage
);

service_dispatcher as {
    command '!randomfact' => respond_by_method 'random_fact';
    also not_command spoken respond_by_method 'memorize_and_recall';
};

sub load_schema {
    my ($self, $db_conn) = @_;

    $db_conn->run(fixup => sub {
        $_->do(q[
            CREATE TABLE IF NOT EXISTS fact_predicates(
                subject_key TEXT,
                copula_key TEXT,
                predicate_key TEXT,
                subject TEXT,
                copula TEXT,
                predicate TEXT,
                PRIMARY KEY (subject_key, copula_key, predicate_key)
            );
        ]);
    });
}

has accepted_copula => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub {
        [ qw( is isn't are aren't ) ],
    },
);

has copula_re => (
    is          => 'ro',
    isa         => 'RegexpRef',
    lazy_build  => 1,
);

sub _build_copula_re {
    my $self = shift;
    my $copula_list = join '|', map { quotemeta } @{ $self->accepted_copula };
    return qr/\b($copula_list)\b/;
}

sub store_fact {
    my ($self, $subject, $copula, $predicate) = @_;

    $self->db_conn->run(fixup => sub {
        $_->do(q[
            INSERT INTO fact_predicates(subject_key, copula_key, predicate_key, subject, copula, predicate)
            VALUES (?, ?, ?, ?, ?, ?)
        ], undef, lc($subject), lc($copula), lc($predicate), $subject, $copula, $predicate);
    });
}

sub recall_fact {
    my ($self, $subject, $copula) = @_;

    my @fact = $self->db_conn->run(fixup => sub {
        $_->selectrow_array(q[
            SELECT subject, copula, predicate
              FROM fact_predicates
             WHERE subject_key = ?
          ORDER BY copula_key = ? DESC, RANDOM()
             LIMIT 1
        ], undef, lc($subject), lc($copula));
    });

    return @fact;
}

sub _trim { local $_ = shift; s/^\s+//; s/\s+$//; $_ }
sub memorize_and_recall {
    my ($self, $message) = @_;

    my $regex = $self->copula_re;
    my $text = $message->text;
    my ($subject, $copula, $predicate) = map { _trim($_) } split /$regex/, $text, 2;

    if ($subject and $copula and $predicate) {
        if (lc($subject) eq 'what' or lc($subject) eq 'who') {
            $predicate =~ s/\?$//;
            $subject = $predicate;
            ($subject, $copula, $predicate) = $self->recall_fact($subject, $copula);
            return "$subject $copula $predicate" if $predicate;
            return;
        }

        else {
            $self->store_fact($subject, $copula, $predicate);
        }
    }

    else {
        my @fact = $self->recall_fact($text, '');
        return join ' ', @fact if @fact;
        return;
    }

    return;
}

sub random_fact {
    my ($self, $message) = @_;

    my @fact = $self->db_conn->run(fixup => sub {
        $_->selectrow_array(q[
            SELECT subject, copula, predicate
              FROM fact_predicates
          ORDER BY RANDOM()
             LIMIT 1
        ]);
    });

    return join ' ', @fact if @fact;
    return 'I do not know any facts.';
}

sub initialize { }

__PACKAGE__->meta->make_immutable;
