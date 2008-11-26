package NanoA::Form;

use strict;
use warnings;
use utf8;
use Scalar::Util;

our %Defaults;

BEGIN {
    %Defaults = (
        secure => 1,
        action => undef,
        fields => undef, # need to be copied
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $fields = delete $args{fields} || [];
    die 'action アトリビュートが設定されていません'
        unless defined $args{action};
    my $self = bless {
        %Defaults,
        %args,
        fields => [], # filled afterwards
    }, $klass;
    die "フィールドの値が tag => attributes の型式ではありません"
        unless @$fields % 2 == 0;
    for (my $i = 0; $i < @$fields; $i += 2) {
        my $name = $fields->[$i];
        my $opts = $fields->[$i + 1];
        die 'フィールドの type が指定されていないか、無効です'
            unless $opts->{type} =~ /^(text|hidden|radio|select|checkbox|textarea)$/;
        my $field_klass = 'NanoA::Form::Field::' . ucfirst $opts->{type};
        push @{$self->{fields}}, $field_klass->new(
            %$opts,
            name => $name,
        );
    }
    $self;
}

sub field {
    my ($self, $n) = @_;
    for my $f (@{$self->{fields}}) {
        return $f
            if $f->name eq $n;
    }
    return;
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
        map {
            $_->type eq 'hidden' ? ${$_->to_html} : join(
                '',
                '<tr><th>',
                NanoA::escape_html($_->label),
                '</th><td>',
                ${$_->to_html},
                '</td></tr>',
            )
        } @{$self->{fields}},
        '</table></form>',
    );
    NanoA::raw_string($html);
}

sub validate {
    my ($self, $q) = @_;
    my @errors;
    for my $f (@{$self->{fields}}) {
        if (my $error = $f->validate([ $q->param($f->name) ])) {
            push @errors, $error;
        }
    }
    @errors ? \@errors : undef;
}

sub _build_element {
    my ($tag, $base, $extra, $omit, $append) = @_;
    my %attr = (
        (map {
            ($_ => $base->{$_})
        } grep {
            ! exists $omit->{$_} && ! /^(label|required)$/
        } keys %$base),
        %$extra,
    );
    my $html = join(
        '',
        '<' . $tag,
        (map {
            ' ' . $_ . '="' . NanoA::escape_html($attr{$_}) . '"'
        } sort grep {
            defined $attr{$_}
        } keys %attr),
        $append ? ('>', $append, '</', $tag, '>') : ' />',
    );
    return NanoA::raw_string($html);
}

package NanoA::Form::Error;

use strict;
use warnings;
use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        message => 'form error',
        field   => undef,
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    my $self = bless {
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    }, $klass;
    $self;
}

package NanoA::Form::Field;

use strict;
use warnings;
use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        name       => undef,
        # attributes below are for validation
        label      => undef,
        required   => undef,
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    die 'name アトリビュートが必要です'
        unless $args{name};
    my $self = bless {
        %Defaults,
        %args,
    }, $klass;
    delete $self->{type}; # just to make sure
    $self->{label} ||= ucfirst($self->{name});
    $self;
}

package NanoA::Form::Field::Text;

use strict;
use warnings;
use utf8;

use base qw(NanoA::Form::Field);

our %Defaults;

BEGIN {
    %Defaults = (
        min_length => undef,
        max_length => undef,
        regexp     => undef,
    );
    NanoA::make_accessors(__PACKAGE__, keys %Defaults);
};

sub new {
    my $klass = shift;
    $klass->SUPER::new(
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    );
}

sub type { 'text' }

sub to_html {
    my ($self, $values) = @_;
    return NanoA::Form::_build_element(
        'input',
        $self,
        {
            type  => $self->type,
            $values && @$values ? (value => $values->[0]) : (),
        },
        \%Defaults,
    );
}

sub validate {
    my ($self, $values) = @_;
    
    return NanoA::Form::Error->new(
        message => '不正な入力値です',
        field   => $self,
    ) if @$values >= 2;
    if (@$values == 0 || $values->[0] eq '') {
        # is empty
        return unless $self->required;
        return NanoA::Form::Error->new(
            message => $self->label . 'を入力してください',
            field   => $self,
        );
    }
    
    my $value = $values->[0];
    if (my $l = $self->min_length) {
        return NanoA::Form::Error->new(
            message => $self->label . 'が短すぎます',
            field   => $self,
        ) if length($value) < $l;
    }
    if (my $l = $self->max_length) {
        return NanoA::Form::Error->new(
            message => $self->label . 'が長すぎます',
            field   => $self,
        ) if $l < length $value;
    }
    if (my $r = $self->regexp) {
        return NanoA::Form::Error->new(
            message => '無効な' . $self->label . 'です',
            field   => $self,
        ) if $value !~ /$r/;
    }
    
    return;
}

package NanoA::Form::Field::Hidden;

use base qw(NanoA::Form::Field::Text); # oh,oh

sub type { 'hidden' }

package NanoA::Form::Field::RadioOption;

use strict;
use warnings;
use utf8;

BEGIN {
    NanoA::make_accessors(__PACKAGE__, qw(parent value label checked));
};

sub new {
    my $klass = shift;
    my $self = bless {
        @_ == 1 ? %{$_[0]} : @_,
    }, $klass;
    Scalar::Util::weaken($self->{parent});
    $self;
}

sub to_html {
    my ($self, $values) = @_;
    my %base = (
        %{$self->{parent}},
        %$self,
    );
    $base{id} ||= 'nanoa_form_radio_' . int(rand(1000000));
    my $html = ${NanoA::Form::_build_element(
        'input',
        \%base,
        {
            type    => 'radio',
            value   => $self->{value},
            ($values && grep { $_ eq $self->{value} } @$values)
                ? (checked => 1) : (),
        },
        {
            options => 1,
            parent  => 1,
        },
    )};
    $html = join(
        '',
        $html,
        '<label for="',
        NanoA::escape_html($base{id}),
        '">',
        NanoA::escape_html($self->{label}),
        '</label>',
    );
    return NanoA::raw_string($html);
}

package NanoA::Form::Field::Radio;

use strict;
use warnings;
use utf8;

use base qw(NanoA::Form::Field);

BEGIN {
    NanoA::make_accessors(__PACKAGE__, qw(options));
};

sub new {
    my $klass = shift;
    my $self = $klass->SUPER::new(@_);
    my @options; # build new list
    if (my $in = $self->{options}) {
        die 'options の値が value => attributes の型式ではありません'
            unless @$in % 2 == 0;
        for (my $i = 0; $i < @$in; $i += 2) {
            my $value = $in->[$i];
            my $attributes = $in->[$i + 1];
            push @options, NanoA::Form::Field::RadioOption->new(
                %$attributes,
                value  => $value,
                parent => $self,
            );
        }
    }
    $self->{options} = \@options;
    $self;
}

sub tag { 'input' }
sub type { 'radio' }

sub to_html {
    my ($self, $values) = @_;
    my $html = join(
        ' ',
        map {
            ${$_->to_html($values)}
        } @{$self->{options}},
    );
    return NanoA::raw_string($html);
}

sub validate {
    my ($self, $values) = @_;
    
    return NanoA::Form::Error->new(
        message => '不正な入力値です',
        field   => $self,
    ) if @$values >= 2;
    if (@$values == 0 || $values->[0] eq '') {
        # is empty
        return unless $self->required;
        return NanoA::Form::Error->new(
            message => $self->label . 'を選択してください',
            field   => $self,
        );
    }
    
    my $value = $values->[0];
    return NanoA::Form::Error->new(
        message => '不正な入力値です',
        field   => $self,
    ) unless scalar grep { $_->value eq $value } @{$self->{options}};
    
    return;
}

1;
