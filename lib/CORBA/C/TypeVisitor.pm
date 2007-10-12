use strict;
use warnings;

#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::TypeVisitor;

our $VERSION = '2.60';

# builds $node->{c_arg}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub _get_type {
    my $self = shift;
    my ($type) = @_;

    if (ref $type) {
        return $type;
    }
    else {
        $self->{symbtab}->Lookup($type);
    }
}

sub _get_c_arg {
    my $self = shift;
    my ($type, $v_name, $attr) = @_;

    my $t_name = $type->{c_name};
    return $t_name . CORBA::C::nameattr->NameAttr($self->{symbtab}, $type, $attr) . $v_name;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self);
        }
    }
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.6     Import Declaration
#

sub visitImport {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    # C mapping is aligned with CORBA 2.1
}

sub visitInitializer {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    # empty
}

sub visitNativeType {
    # C mapping is aligned with CORBA 2.1
}

#
#   3.11.2  Constructed Types
#

sub visitStructType {
    # empty
}

sub visitUnionType {
    # empty
}

sub visitEnumType {
    # empty
}

#
#   3.12    Exception Declaration
#

sub visitException {
    # empty
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_type($node->{type});
    $node->{c_arg} = $self->_get_c_arg($type, q{}, 'return');
    foreach (@{$node->{list_param}}) {  # parameter
        $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $node->{_get}->visit($self);
    $node->{_set}->visit($self) if (exists $node->{_set});
}

#
#   3.15    Repository Identity Related Declarations
#

sub visitTypeId {
    # empty
}

sub visitTypePrefix {
    # empty
}

#
#   3.16    Event Declaration
#

#
#   3.17    Component Declaration
#

sub visitProvides {
    # empty
}

sub visitUses {
    # empty
}

sub visitPublishes {
    # empty
}

sub visitEmits {
    # empty
}

sub visitConsumes {
    # empty
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
}

sub visitFinder {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
}

##############################################################################

package CORBA::C::nameattr;

#
#   See 1.21    Summary of Argument/Result Passing
#

# needs $node->{c_name} and $node->{length}

sub NameAttr {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    my $class = ref $node;
    $class = 'BasicType' if ($node->isa('BasicType'));
    $class = 'AnyType' if ($node->isa('AnyType'));
    $class = 'BaseInterface' if ($node->isa('BaseInterface'));
    $class = 'ForwardBaseInterface' if ($node->isa('ForwardBaseInterface'));
    my $func = 'NameAttr' . $class;
    if($proto->can($func)) {
        return $proto->$func($symbtab, $node, $attr);
    }
    else {
        warn "Please implement a function '$func' in '",__PACKAGE__,"'.\n";
    }
}

sub NameAttrBaseInterface {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::NameAttrBaseInterface : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrForwardBaseInterface {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::NameAttrBaseInterface : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrTypeDeclarator {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (exists $node->{array_size}) {
        if (    $attr eq 'in' ) {
            return q{ };
        }
        elsif ( $attr eq 'inout' ) {
            return q{ };
        }
        elsif ( $attr eq 'out' ) {
            if (defined $node->{length}) {      # variable
                return '_slice ** ';
            }
            else {
                return q{ };
            }
        }
        elsif ( $attr eq 'return' ) {
            return '_slice *';
        }
        else {
            warn __PACKAGE__,"::NameAttrTypeDeclarator array : ERROR_INTERNAL $attr \n";
        }
    }
    else {
        my $type = $node->{type};
        unless (ref $type) {
            $type = $symbtab->Lookup($type);
        }
        return $proto->NameAttr($symbtab, $type, $attr);
    }
}

sub NameAttrNativeType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    # C mapping is aligned with CORBA 2.1
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::NameAttrNativeType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrBasicType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::NameAttrBasicType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrAnyType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return ' * ';
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' ** ';
    }
    elsif ( $attr eq 'return' ) {
        return ' *';
    }
    else {
        warn __PACKAGE__,"::NameAttrAnyType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrStructType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return ' * ';
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        if (defined $node->{length}) {      # variable
            return ' ** ';
        }
        else {
            return ' * ';
        }
    }
    elsif ( $attr eq 'return' ) {
        if (defined $node->{length}) {      # variable
            return ' *';
        }
        else {
            return q{};
        }
    }
    else {
        warn __PACKAGE__,"::NameAttrStructType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrUnionType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return ' * ';
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        if (defined $node->{length}) {      # variable
            return ' ** ';
        }
        else {
            return ' * ';
        }
    }
    elsif ( $attr eq 'return' ) {
        if (defined $node->{length}) {      # variable
            return ' *';
        }
        else {
            return q{};
        }
    }
    else {
        warn __PACKAGE__,"::NameAttrUnionType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrEnumType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::AttrNameEnumType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrSequenceType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return ' * ';
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' ** ';
    }
    elsif ( $attr eq 'return' ) {
        return ' *';
    }
    else {
        warn __PACKAGE__,"::AttrNameSequenceType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrStringType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::AttrNameStringType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrWideStringType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return q{ };
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::AttrNameWideStringType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrFixedPtType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if (    $attr eq 'in' ) {
        return ' * ';
    }
    elsif ( $attr eq 'inout' ) {
        return ' * ';
    }
    elsif ( $attr eq 'out' ) {
        return ' * ';
    }
    elsif ( $attr eq 'return' ) {
        return q{};
    }
    else {
        warn __PACKAGE__,"::NameAttrFixedPtType : ERROR_INTERNAL $attr \n";
    }
}

sub NameAttrVoidType {
    my $proto = shift;
    my ($symbtab, $node, $attr) = @_;
    if ($attr ne 'return') {
        warn __PACKAGE__,"::NameAttrVoidType : ERROR_INTERNAL \n";
    }
    return q{};
}

1;

