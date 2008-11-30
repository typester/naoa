package HTML::AutoForm;

use utf8;
use Scalar::Util;


our $VERSION;
our %Defaults;
our $DEFAULT_LANG;
our $CLASS_PREFIX;

BEGIN {
    $VERSION = '0.01';
    %Defaults = (
        action       => undef,
        csrf_keyname => '__nanoa_csrf_key',
        fields       => undef, # need to be copied
        secure       => 1,
    );
    Class::Accessor::Lite->mk_accessors(keys %Defaults);
    $DEFAULT_LANG = 'en';
    $CLASS_PREFIX = 'autoform';
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $fields = delete $args{fields} || [];
    for my $n qw(action) {
        die 'mandatory attribute "' . $n . '" is missing'
            unless defined $args{$n};
    }
    my $self = bless {
        %Defaults,
        %args,
        fields => [], # filled afterwards
    }, $klass;
    die 'fields should be supplied in: tag => attributes style'
        unless @$fields % 2 == 0;
    for (my $i = 0; $i < @$fields; $i += 2) {
        my $name = $fields->[$i];
        my $opts = $fields->[$i + 1];
        die 'field type is missing or invalid'
            unless $opts->{type} =~ /^(text|hidden|password|radio|select|checkbox|textarea)$/;
        my $field_klass = 'HTML::AutoForm::Field::' . ucfirst $opts->{type};
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

# the default renderer
sub render {
    my ($self, $query, $csrf_token) = @_;
    
    my $do_validate = $query->request_method eq 'POST'
            || (! $self->secure && %{$query->Vars});
    
    my $html = join(
        '',
        '<form action="',
        _escape_html($self->action),
        '"',
        ($self->secure ? ' method="POST"' : ''),
        '>',
        '<table class="',
        $CLASS_PREFIX,
        '_table">',
        (map {
            sub {
                my $field = shift;
                my @values = $query->param($_->name);
                if ($field->type eq 'hidden') {
                    return $_->render(\@values);
                }
                my @r = (
                    '<tr><th>',
                    _escape_html($field->label),
                    '</th><td>',
                    $field->render(\@values),
                );
                if ($do_validate) {
                    print STDERR "validating: ", $field->name, "\n";
                    if (my $err = $field->validate($query)) {
                        push(
                            @r,
                            '<div class="',
                            $CLASS_PREFIX,
                            '_error">',
                            _escape_html('※' . $err->message),
                            '</div>',
                        );
                    }
                }
                push @r, '</td></tr>';
                @r;
            }->($_)
        } @{$self->{fields}}),
        $self->secure
            ? (
                '<input type="hidden" name="',
                _escape_html($self->csrf_keyname),
                '" value="',
                # TODO: use a different id
                _escape_html($csrf_token),
                '" />',
            ) : (),
        '<tr><th></th><td><input type="submit" value="投稿する" /></td></tr>',
        '</table></form>',
    );
    $html;
}

sub validate {
    my ($self, $query, $check_csrf_callback) = @_;
    
    for my $f (@{$self->{fields}}) {
        if (my $error = $f->validate($query)) {
            return;
        } elsif (my $h = $f->custom) {
            if (my $error = $h->($f, $query)) {
                return;
            }
        }
    }
    if ($self->secure) {
        my $ok;
        if (my $csrf_value = $query->param($self->csrf_keyname)) {
            if ($check_csrf_callback->($csrf_value)) {
                $ok = 1;
            }
        }
        return
            unless $ok;
    }
    1;
}

sub _build_element {
    my ($tag, $base, $extra, $omit, $append) = @_;
    my %attr = (
        (map {
            ($_ => $base->{$_})
        } grep {
            ! exists $omit->{$_} && ! /^(allow_multiple|label|required)$/
        } keys %$base),
        %$extra,
    );
    my $html = join(
        '',
        '<' . $tag,
        (map {
            ' ' . $_ . '="' . _escape_html($attr{$_}) . '"'
        } sort grep {
            defined $attr{$_}
        } keys %attr),
        defined $append ? ('>', $append, '</', $tag, '>') : ' />',
    );
    $html;
}

sub _escape_html {
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    $str;
}

1;

package HTML::AutoForm::Error;

use utf8;

our %Defaults;
our %Errors;

BEGIN {
    # setup accessor
    Class::Accessor::Lite->mk_accessors(qw/code field args/);
    
    # errors
    $Errors{en} = {
        CHOICES_TOO_FEW => sub {
            my $self = shift;
            return 'Please select / input ' . lcfirst($self->field->label) . '.'
                unless $self->field->allow_multiple;
            'Too few items selected for ' . lcfirst($self->field->label) . '.';
        },
        CHOICES_TOO_MANY => sub {
            my $self = shift;
            'Too many items selected for ' . lcfirst($self->field->label) . '.';
        },
        NO_SELECTION => sub {
            my $self = shift;
            'Please select an item from ' . lcfirst($self->field->label) . '.';
        },
        INVALID_INPUT => sub {
            my $self = shift;
            'Invalid input for ' . lcfirst($self->field->label) . '.';
        },
        IS_EMPTY => sub {
            my $self = shift;
            $self->field->label . ' is empty.';
        },
        TOO_SHORT => sub {
            my $self = shift;
            $self->field->label . ' is too short' . '.';
        },
        TOO_LONG => sub {
            my $self = shift;
            $self->field->label . ' is too long' . '.';
        },
        INVALID_DATA => sub {
            my $self = shift;
            'Please check the value of ' . lcfirst($self->field->label);
        },
        CUSTOM => sub {
            my $self = shift;
            $self->args->[0];
        },
    };
    
    # create instance builders
    for my $n (keys %{$Errors{en}}) {
        no strict 'refs';
        *{$n} = sub {
            shift->_new($n, @_);
        };
    }
};

# always use instance builders declared above
sub _new {
    my ($klass, $code, $field, @args) = @_;
    bless {
        code  => $code,
        field => $field,
        args  => \@args,
    }, $klass;
}

sub message {
    my $self = shift;
    my $lang = shift || $HTML::AutoForm::DEFAULT_LANG;
    require "HTML/AutoForm/Error/${lang}.pm"
            unless exists $Errors{$lang};
    $Errors{$lang}->{$self->{code}}->($self);
}

1;
use utf8;

BEGIN {
    $HTML::AutoForm::Error::Errors{ja} = {
        %{$HTML::AutoForm::Error::Errors{en}},
        CHOICES_TOO_FEW => sub {
            my $self = shift;
            return $self->field->label . 'を入力／選択してください'
                unless $self->field->allow_multiple;
            $self->field->label . 'の選択が少なすぎます';
        },
        CHOICES_TOO_MANY => sub {
            my $self = shift;
            $self->field->label . 'の選択が多すぎます';
        },
        NO_SELECTION => sub {
            my $self = shift;
            $self->field->label . 'を選択してください',
        },
        INVALID_INPUT => sub {
            my $self = shift;
            '不正な入力値です (' . $self->field->label . ')';
        },
        IS_EMPTY => sub {
            my $self = shift;
            $self->field->label . 'を入力してください';
        },
        TOO_SHORT => sub {
            my $self = shift;
            $self->field->label . 'が短すぎます';
        },
        TOO_LONG => sub {
            my $self = shift;
            $self->field->label . 'が長すぎます';
        },
        INVALID_DATA => sub {
            my $self = shift;
            $self->field->label . 'の入力を確認してください',
        },
    };
};

1;
package HTML::AutoForm::Field;

use utf8;

our %Defaults;

BEGIN {
    %Defaults = (
        name           => undef,
        # attributes below are for validation
        label          => undef,
        required       => undef,
        custom         => undef,
        allow_multiple => undef,
    );
    Class::Accessor::Lite->mk_accessors(keys %Defaults);
};

sub new {
    my $klass = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    for my $n qw(name) {
        die 'mandotory attribute "' . $n . '" is missing'
            unless $args{$n};
    }
    my $self = bless {
        %Defaults,
        %args,
    }, $klass;
    delete $self->{type}; # just to make sure
    $self->{label} ||= ucfirst($self->{name});
    $self;
}

sub choices_minmax {
    my $self = shift;
    
    my $req = $self->required;
    return @$req
        if ref $req eq 'ARRAY';
    return ($req, $req)
        if $req;
    return (0, $self->allow_multiple ? 999999 : 1);
}

sub validate {
    my ($self, $query) = @_;
    my @values = $query->param($self->name);
    
    # check numbers
    my ($min_choices, $max_choices) = $self->choices_minmax();
    if (@values < $min_choices) {
        return HTML::AutoForm::Error->CHOICES_TOO_FEW($self);
    }
    if ($max_choices < @values) {
        return HTML::AutoForm::Error->CHOICES_TOO_MANY($self);
    }
    
    # simply return if the field was optional and there is no data
    return
        unless @values;
    
    # call type-dependent logic
    if (my $error = $self->_per_field_validate($query)) {
        return $error;
    }
    
    # call custom logic
    if (my $f = $self->custom) {
        if (my $error = $f->($self, $query)) {
            return $error;
        }
    }
    
    return;
}

sub _validate_choice {
    my ($self, $query) = @_;
    my $options = $self->options;
    for my $value ($query->param($self->name)) {
        return HTML::AutoForm::Error->NO_SELECTION($self)
            if $value eq '';
        return HTML::AutoForm::Error->INVALID_INPUT($self)
            unless scalar grep { $value eq $_->value } @$options;
    }
    return;
}

1;
package HTML::AutoForm::Field::AnyText;

use utf8;

our @ISA;
our %Defaults;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field);
    %Defaults = (
        min_length => undef,
        max_length => undef,
        regexp     => undef,
    );
    Class::Accessor::Lite->mk_accessors(keys %Defaults);
};

sub new {
    my $klass = shift;
    my $self = $klass->SUPER::new(
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    );
    if (my $r = $self->regexp) {
        # special mappings
        if (! ref($r) && $r eq 'email') {
            # from http://www.tt.rim.or.jp/~canada/comp/cgi/tech/mailaddrmatch/
            $self->regexp(qr/^[\x01-\x7F]+@(([-a-z0-9]+\.)*[a-z]+|\[\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\])/oi);
        }
    }
    $self;
}

sub render {
    my ($self, $values) = @_;
    return HTML::AutoForm::_build_element(
        'input',
        {
            ($self->type ne 'hidden' ? (
                class =>
                    $HTML::AutoForm::CLASS_PREFIX . '_field_' . $self->type,
            ) : ()),
            %$self,
        },
        {
            type  => $self->type,
            $values && @$values ? (value => $values->[0]) : (),
        },
        \%Defaults,
    );
}

sub _per_field_validate {
    my ($self, $query) = @_;
    my $value = $query->param($self->name);
    
    if ($value eq '') {
        # is empty
        return unless $self->required;
        return HTML::AutoForm::Error->IS_EMPTY($self);
    }
    if (my $l = $self->min_length) {
        return HTML::AutoForm::Error->TOO_SHORT($self)
            if length($value) < $l;
    }
    if (my $l = $self->max_length) {
        return HTML::AutoForm::Error->TOO_LONG($self)
            if $l < length $value;
    }
    if (my $r = $self->regexp) {
        return HTML::AutoForm::Error->INVALID_DATA($self)
            if $value !~ /$r/;
    }
    
    return;
}

1;
package HTML::AutoForm::Field::Checkbox;

use utf8;

our @ISA;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::InputSet);
};

sub type { 'checkbox' }

sub allow_multiple {
    1;
}

sub _per_field_validate {
    goto \&HTML::AutoForm::Field::_validate_choice;
}

1;
package HTML::AutoForm::Field::Hidden;

use utf8;

our @ISA;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::AnyText);
};

sub type { 'hidden' }

1;
package HTML::AutoForm::Field::InputCheckable;

use utf8;

BEGIN {
    Class::Accessor::Lite->mk_accessors(qw(parent value label checked));
};

sub new {
    my $klass = shift;
    my $self = bless {
        @_ == 1 ? %{$_[0]} : @_,
    }, $klass;
    Scalar::Util::weaken($self->{parent});
    $self;
}

sub render {
    my ($self, $values) = @_;
    my %base = (
        %{$self->{parent}},
        %$self,
    );
    $base{id} ||=
        $HTML::AutoForm::CLASS_PREFIX . '_radio_' . int(rand(1000000));
    $base{class} ||=
        $HTML::AutoForm::CLASS_PREFIX . '_field_' . $self->parent->type;
    my $html = join(
        '',
        HTML::AutoForm::_build_element(
            'input',
            \%base,
            {
                type    => $self->parent->type,
                value   => $self->{value},
                ($values
                     ? grep { $_ eq $self->{value} } @$values
                         : $self->{checked})
                    ? (checked => 1) : (),
            },
            {
                options => 1,
                parent  => 1,
                checked => 1,
            },
        ),
        '<label for="',
        HTML::AutoForm::_escape_html($base{id}),
        '">',
        HTML::AutoForm::_escape_html($self->{label}),
        '</label>',
    );
    $html;
}

1;
package HTML::AutoForm::Field::InputSet;

use utf8;

our @ISA;
BEGIN {
    @ISA = qw(HTML::AutoForm::Field);
    Class::Accessor::Lite->mk_accessors(qw(options));
};

sub new {
    my $klass = shift;
    my $self = $klass->SUPER::new(@_);
    my @options; # build new list
    if (my $in = $self->{options}) {
        die 'options should be in value => attributes form'
            unless @$in % 2 == 0;
        for (my $i = 0; $i < @$in; $i += 2) {
            my $value = $in->[$i];
            my $attributes = $in->[$i + 1];
            push @options, HTML::AutoForm::Field::InputCheckable->new(
                label  => ucfirst $value,
                %$attributes,
                value  => $value,
                parent => $self,
            );
        }
    }
    $self->{options} = \@options;
    $self;
}

sub render {
    my ($self, $values) = @_;
    my $html = join(
        ' ',
        map {
            $_->render($values)
        } @{$self->{options}},
    );
    $html;
}

1;
package HTML::AutoForm::Field::Option;

use utf8;

BEGIN {
    Class::Accessor::Lite->mk_accessors(qw(value label selected));
};

sub new {
    my $klass = shift;
    my $self = bless {
        @_ == 1 ? %{$_[0]} : @_,
    }, $klass;
    $self;
}

sub render {
    my ($self, $values) = @_;
    return HTML::AutoForm::_build_element(
        'option',
        $self,
        ($values ? grep { $_ eq $self->{value} } @$values : $self->{selected})
            ? { selected => 1 } : {},
        { selected => 1 },
        $self->{label},
    );
}

1;
package HTML::AutoForm::Field::Password;

use utf8;

our @ISA;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::AnyText);
};

sub type { 'password' }

1;
package HTML::AutoForm::Field::Radio;

use utf8;

our @ISA;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::InputSet);
};

sub type { 'radio' }

sub _per_field_validate {
    goto \&HTML::AutoForm::Field::_validate_choice;
}

1;
package HTML::AutoForm::Field::Select;

use utf8;

our @ISA;
our %Defaults;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field);
    %Defaults = (
        multiple => undef,
        options  => undef, # instantiated in constructor
    );
    Class::Accessor::Lite->mk_accessors(keys %Defaults);
};

sub new {
    my $klass = shift;
    my $self = $klass->SUPER::new(@_);
    my @options; # build new list
    if (my $in = $self->{options}) {
        die 'options not in value => attributes form'
            unless @$in % 2 == 0;
        for (my $i = 0; $i < @$in; $i += 2) {
            my $value = $in->[$i];
            my $attributes = $in->[$i + 1];
            push @options, HTML::AutoForm::Field::Option->new(
                %$attributes,
                value  => $value,
            );
        }
    }
    $self->{options} = \@options;
    $self;
}

sub type { 'select' }

sub allow_multiple {
    goto \&multiple;
}

sub render {
    my ($self, $values) = @_;
    return HTML::AutoForm::_build_element(
        'select',
        {
            class => $HTML::AutoForm::CLASS_PREFIX . '_field_' . (
                $self->multiple ? 'multiple' : 'select',
            ),
            %$self,
        },
        {},
        { options => 1, },
        join('', map { $_->render($values) } @{$self->{options}}),
    );
}

sub _per_field_validate {
    goto \&HTML::AutoForm::Field::_validate_choice;
}

1;
package HTML::AutoForm::Field::Text;

use utf8;

our @ISA;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::AnyText);
};

sub type { 'text' }

1;
package HTML::AutoForm::Field::Textarea;

use utf8;

our @ISA;

BEGIN {
    @ISA = qw(HTML::AutoForm::Field::AnyText);
};

sub type { 'textarea' }

sub render {
    my ($self, $values) = @_;
    return HTML::AutoForm::_build_element(
        'textarea',
        {
            class => $HTML::AutoForm::CLASS_PREFIX . '_field_' . $self->type,
            %$self,
        },
        {},
        {
            %HTML::AutoForm::Field::AnyText::Defaults,
            value => 1,
        },
        HTML::AutoForm::_escape_html(
            $values && @$values ? $values->[0] : $self->{value} || ''
        ),
    );
}

1;
1;
