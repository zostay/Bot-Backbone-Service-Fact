package Bot::Backbone::Service::Fact::Keyword;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
    Bot::Backbone::Service::Role::Storage
);

service_dispatcher as {
    command '!keyword' => given_parameters {
        parameter 'keyword' => ( match => qr/.+/ );
        parameter 'response' => ( match_original => qr/.+/ );
    } run_this_method 'learn_keyword';

    command '!forget_keyword' => given_parameters {
        parameter 'keyword' => ( match => qr/.+/ );
        parameter 'response' => ( match_original => qr/.+/ );
    } run_this_method 'forget_keyword';

    command '!forget_keyword' => given_parameters {
        parameter 'keyword' => ( match => qr/.+/ );
    } run_this_method 'forget_keyword';

    also not_command spoken respond_by_method 'recall_keyword_sometimes';
};

sub load_schema {
    my ($self, $db_conn) = @_;

    $db_conn->run(fixup => sub {
        $_->do(q[
            CREATE TABLE IF NOT EXISTS fact_keywords(
                keyword TEXT,
                response TEXT,
                PRIMARY KEY (keyword, response)
            )
        ]);
    });
}

has frequency => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0.1,
);

sub learn_keyword {
    my ($self, $message) = @_;

    my $keyword = $message->parameters->{keyword};
    my $response = $message->parameters->{response};

    $self->db_conn->run(fixup => sub {
        $_->do(q[
            INSERT OR IGNORE INTO fact_keywords(keyword, response)
            VALUES (?, ?)
        ], undef, $keyword, $response);
    });

    return 1;
}

sub forget_keyword {
    my ($self, $message) = @_;

    my $keyword = $message->parameters->{keyword};
    my $response = $message->parameters->{response};

    if ($response and $response =~ /\S/) {
        $self->db_conn->run(fixup => sub {
            $_->do(q[
                DELETE FROM fact_keywords
                WHERE keyword = ? AND response = ?
            ], undef, $keyword, $response);
        });
    }
    else {
        $self->db_conn->run(fixup => sub {
            $_->do(q[
                DELETE FROM fact_keywords
                WHERE keyword = ?
            ], undef, $keyword);
        });
    }

    return 1;
}

sub recall_keyword_sometimes {
    my ($self, $message) = @_;

    return unless rand() < $self->frequency;

    my @words = map { $_->text } $message->all_args;
    my $qlist = join ', ', ('?') x scalar @words;
    my ($response) = $self->db_conn->run(fixup => sub {
        $_->selectrow_array(qq[
            SELECT response
              FROM fact_keywords
             WHERE keyword IN ($qlist)
          ORDER BY RANDOM()
             LIMIT 1
        ], undef, @words);
    });

    return unless $response;
    return $response;
}

sub initialize { }

__PACKAGE__->meta->make_immutable;
