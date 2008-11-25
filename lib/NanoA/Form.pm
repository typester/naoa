package NanoA::Form;

use strict;
use warnings;
use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        secure   => 1,
        elements => undef, # need be copied
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $elements = delete $args{elements} || [];
    my $self = bless {
        %Defaults,
        %args,
        elements => [], # filled laterwards
    }, $klass;
    die "フォームの値が tag => attributes の型式ではありません"
        unless @$elements % 2 == 0;
    for (my $i = 0; $i < @$elements; $i += 2) {
        push(
            @{$self->{elements}},
            NanoA::Form::Element->new(
                %{$elements->[$i + 1]},
                tag => lc $elements->[$i],
            ),
        );
    }
    $self;
}

sub to_html {
    my $self = shift;
    
}

sub validate {
    my ($self, $q) = @_;
    my @errors;
    for my $e (@{$self->{elements}}) {
        if (my $error = $e->validate([ $q->param($e->name) ])) {
            push @errors, $error;
        }
    }
    @errors;
}

package NanoA::Form::Error;

use strict;
use warnings;
use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        message => 'form error',
        element => undef,
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    bless {
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    }, $klass;
}

package NanoA::Form::Element;

use strict;
use warnings;
use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        tag        => undef,
        name       => undef,
        type       => undef,
        options    => undef,
        selected   => undef,
        checked    => undef,
        value      => undef,
        # attributes below are for validation
        label      => undef,
        required   => 1,
        min_length => undef,
        max_length => undef,
        regexp     => undef,
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    for my $n qw(tag name) {
        die $n . ' アトリビュートが必要です'
            unless $args{$n};
    }
    my $self = bless {
        %Defaults,
        %args,
    }, $klass;
    $self->{label} ||= ucfirst($self->{name});
    $self;
}

sub validate {
    my ($self, $values) = @_;
    
    if (@$values == 0 || ($self->tag eq 'input' && $values->[0] eq '')) {
        # is empty
        return unless $self->required;
        return NanoA::Form::Error->new(
            message => $self->label . 'を入力してください',
            element => $self,
        );
    }
    if (my $l = $self->min_length) {
        return NanoA::Form::Error->new(
            message => $self->label . 'が短すぎます',
            element => $self,
        ) if grep { length($_) < $l } @$values;
    }
    if (my $l = $self->max_length) {
        return NanoA::Form::Error->new(
            message => $self->label . 'が長すぎます',
            element => $self,
        ) if grep { $l < length($_) } @$values;
    }
    if (my $r = $self->regexp) {
        return NanoA::Form::Error->new(
            message => '無効な' . $self->label . 'です',
            element => $self,
        ) if grep { $_ !~ /$r/ }@$values;
    }
    
    return;
}

sub to_html {
    my $self = shift;
    my $html = join(
        ' ',
        '<' . $self->tag,
        map {
            $_ . '="' . NanoA::escape_html($self->{$_}) . '"',
        } grep {
            $_ !~ /^(tag|label|required|min_length|max_length|regexp|options|selected)$/
                and defined $self->{$_}
            } sort keys %$self,
    );
    if ($self->tag eq 'input') {
        $html .= ' />';
    } elsif ($self->tag eq 'select') {
        my $options = $self->options;
        $html = join(
            '',
            $html,
            '>',
            (map {
                join(
                    '',
                    '<option value="',
                    NanoA::escape_html($options->[$_ * 2]),
                    '"',
                    ($options->[$_ * 2 + 1]->{selected} ? ' selected' : ''),
                    '>',
                    NanoA::escape_html($options->[$_ * 2 + 1]->{label}),
                    '</option>',
                ),
            } 0..((@$options - 1) / 2)),
            '</select>',
        );
    } elsif ($self->tag eq 'textarea') {
        $html .= NanoA::escape_html($self->value) . '</textarea>';
    } else {
        die 'unexpected tag: ' . $self->tag;
    }
    return NanoA::raw_string($html);
}

1;
