package NanoA::Form;

use strict;
use warnings;
use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        secure   => 1,
        action   => undef,
        elements => undef, # need be copied
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $elements = delete $args{elements} || [];
    die 'action アトリビュートが設定されていません'
        unless defined $args{action};
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
    my $html = join(
        '',
        '<form action="',
        NanoA::escape_html($self->action),
        '"',
        ($self->secure ? ' method="POST"' : ''),
        '>',
        '<table class="nanoa_form_table">',
        (map {
            join(
                '',
                '<tr><th>',
                NanoA::escape_html($_->label),
                '</th><td>',
                ${$_->to_html},
                '</td></tr>',
            )
        } grep {
            ! ($_->tag eq 'input' && $_->type eq 'hidden')
        } @{$self->{elements}}),
        '</table></form>',
    );
    NanoA::raw_string($html);
}

sub validate {
    my ($self, $q) = @_;
    my @errors;
    for my $e (@{$self->{elements}}) {
        if (my $error = $e->validate([ $q->param($e->name) ])) {
            push @errors, $error;
        }
    }
    @errors ? \@errors : undef;
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

our %Common_Defaults;
our %Per_Tag_Attributes;

BEGIN {
    %Defaults = (
        tag        => undef,
        name       => undef,
        # attributes below are dependent to tag
        type       => undef,
        options    => undef,
        checked    => undef,
        value      => undef,
        multiple   => undef,
        # attributes below are for validation
        label      => undef,
        required   => 1,
        min_length => undef,
        max_length => undef,
        regexp     => undef,
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
    %Per_Tag_Attributes = (
        input    => { map { ($_ => 1) } qw/type checked value/ },
        select   => { map { ($_ => 1) } qw/multiple/ },
        textarea => {},
    );
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
    my $tag = $self->tag;
    my $per_tag_attr = $Per_Tag_Attributes{$tag};
    my $html = join(
        ' ',
        '<' . $tag,
        map {
            $_ . '="' . NanoA::escape_html($self->{$_}) . '"'
        } sort grep {
            ($_ !~ /^(?:tag|type|options|checked|value|label|required|min_length|max_length|regexp)$/ || $per_tag_attr->{$_}) && defined $self->{$_}
        } keys %$self,
    );
    if ($tag eq 'input') {
        $html .= ' />';
    } elsif ($tag eq 'select') {
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
    } elsif ($tag eq 'textarea') {
        $html .= NanoA::escape_html($self->value) . '</textarea>';
    } else {
        die 'unexpected tag: ' . $tag;
    }
    return NanoA::raw_string($html);
}

1;
