use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v2.4)
#
#			C Language Mapping Specification, New Edition June 1999
#

package CliteralVisitor;

# needs $node->{c_name} (CnameVisitor) for Enum
# builds $node->{c_literal}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{key} = 'c_literal';
	bless($self, $class);
	return $self;
}

#
#	3.5		OMG IDL Specification
#

sub visitNameSpecification {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.6		Module Declaration
#

sub visitNameModule {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.7		Interface Declaration
#

sub visitNameInterface {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = 1;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

sub visitNameForwardInterface {
	# empty
}

#
#	3.8		Value Declaration
#

sub visitNameRegularValue {
	# C mapping is aligned with CORBA 2.1
}

sub visitNameBoxedValue {
	# C mapping is aligned with CORBA 2.1
}

sub visitNameAbstractValue {
	# C mapping is aligned with CORBA 2.1
}

sub visitNameForwardRegularValue {
	# C mapping is aligned with CORBA 2.1
}

sub visitNameForwardAbstractValue {
	# C mapping is aligned with CORBA 2.1
}

#
#	3.9		Constant Declaration
#

sub visitNameConstant {
	my $self = shift;
	my($node) = @_;
	$node->{value}->visitName($self);		# expression
}

sub _Eval {
	my $self = shift;
	my($list_expr,$type) = @_;
	my $elt = pop @{$list_expr};
	if (       $elt->isa('BinaryOp') ) {
		my $right = $self->_Eval($list_expr,$type);
		if (	   $elt->{op} eq '>>'
				or $elt->{op} eq '<<' ) {
			$right =~ s/[LU]+$//;
		}
		my $left = $self->_Eval($list_expr,$type);
		return "(" . $left . " " . $elt->{op} . " " . $right . ")";
	} elsif (  $elt->isa('UnaryOp') ) {
		my $right = $self->_Eval($list_expr,$type);
		return $elt->{op} . $right;
	} elsif (  $elt->isa('Constant')
			or $elt->isa('Enum') ) {
		return $elt->{c_name};
	} elsif (  $elt->isa('Literal') ) {
		$elt->visitName($self,$type);
		return $elt->{$self->{key}};
	} else {
		warn __PACKAGE__," _Eval: INTERNAL ERROR ",ref $elt,".\n";
		return undef;
	}
}

sub visitNameExpression {
	my $self = shift;
	my($node) = @_;
	my @list_expr = @{$node->{list_expr}};		# create a copy
	$node->{$self->{key}} = $self->_Eval(\@list_expr,$node->{type});
}

sub visitNameIntegerLiteral {
	my $self = shift;
	my($node,$type) = @_;
	my $str = $node->{value};
	$str =~ s/^\+//;
	unless (exists $type->{auto}) {
		if (	  $type->{value} eq 'unsigned short' ) {
			$str .= 'U';
		} elsif ( $type->{value} eq 'long' ) {
			$str .= 'L';
		} elsif ( $type->{value} eq 'long long' ) {
			$str .= 'LL';
		} elsif ( $type->{value} eq 'unsigned long' ) {
			$str .= 'UL';
		} elsif ( $type->{value} eq 'unsigned long long' ) {
			$str .= 'ULL';
		}
	}
	$node->{$self->{key}} = $str;
}

sub visitNameStringLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C*",$node->{value};
	my $str = "\"";
	foreach (@list) {
		if ($_ < 32 or $_ >= 128) {
			$str .= sprintf "\\x%02x",$_;
		} else {
			$str .= chr $_;
		}
	}
	$str .= "\"";
	$node->{$self->{key}} = $str;
}

sub visitNameWideStringLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C*",$node->{value};
	my $str = "L\"";
	foreach (@list) {
		if ($_ < 32 or ($_ >= 128 and $_ < 256)) {
			$str .= sprintf "\\x%02x",$_;
		} elsif ($_ >= 256) {
			$str .= sprintf "\\u%04x",$_;
		} else {
			$str .= chr $_;
		}
	}
	$str .= "\"";
	$node->{$self->{key}} = $str;
}

sub visitNameCharacterLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C",$node->{value};
	my $c = $list[0];
	my $str = "'";
	if ($c < 32 or $c >= 128) {
		$str .= sprintf "\\x%02x",$c;
	} else {
		$str .= chr $c;
	}
	$str .= "'";
	$node->{$self->{key}} = $str;
}

sub visitNameWideCharacterLiteral {
	my $self = shift;
	my($node) = @_;
	my @list = unpack "C",$node->{value};
	my $c = $list[0];
	my $str = "L'";
	if ($c < 32 or ($c >= 128 and $c < 256)) {
		$str .= sprintf "\\x%02x",$c;
	} elsif ($c >= 256) {
		$str .= sprintf "\\u%04x",$c;
	} else {
		$str .= chr $c;
	}
	$str .= "'";
	$node->{$self->{key}} = $str;
}

sub visitNameFixedPtLiteral {
	my $self = shift;
	my($node) = @_;
	my $type = $node->{type};
	my $str = "\"";
	$str .= $node->{value};
	$str .= "\"";
	$node->{$self->{key}} = $str;
}

sub visitNameFloatingPtLiteral {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{value};
}

sub visitNameBooleanLiteral {
	my $self = shift;
	my($node) = @_;
	if ($node->{value} eq 'TRUE') {
		$node->{$self->{key}} = '1';
	} else {
		$node->{$self->{key}} = '0';
	}
}

#
#	3.10	Type Declaration
#

sub visitNameTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);
	}
}

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{modifier});	# native IDL2.2
	$node->{type}->visitName($self);
	if (exists $node->{array_size}) {
		foreach (@{$node->{array_size}}) {
			$_->visitName($self);			# expression
		}
	}
}

#
#	3.10.1	Basic Types
#

sub visitNameBasicType {
	# empty
}

sub visitNameAnyType {
	# empty
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = 1;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);				# single or array
	}
}

sub visitNameArray {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self);
	foreach (@{$node->{array_size}}) {
		$_->visitName($self);				# expression
	}
}

sub visitNameSingle {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self);
}

#	3.10.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = 1;
	$node->{type}->visitName($self);
	foreach (@{$node->{list_expr}}) {
		$_->visitName($self);				# case
	}
}

sub visitNameCase {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_label}}) {
		$_->visitName($self);				# default or expression
	}
	$node->{element}->visitName($self);		# array or single
}

sub visitNameDefault {
	# empty
}

sub visitNameElement {
	my $self = shift;
	my($node) = @_;
	$node->{value}->visitName($self);		# array or single
}

#	3.10.2.3	Enumerations
#

sub visitNameEnumType {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_expr}}) {
		$_->visitName($self);				# enum
	}
}

sub visitNameEnum {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{value};
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitNameForwardStructType {
	# empty
}

sub visitNameForwardUnionType {
	# empty
}

#
#	3.10.4	Template Types
#

sub visitNameSequenceType {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self);
	$node->{max}->visitName($self) if (exists $node->{max});
}

sub visitNameStringType {
	my $self = shift;
	my($node) = @_;
	$node->{max}->visitName($self) if (exists $node->{max});
}

sub visitNameWideStringType {
	my $self = shift;
	my($node) = @_;
	$node->{max}->visitName($self) if (exists $node->{max});
}

sub visitNameFixedPtType {
	my $self = shift;
	my($node) = @_;
	$node->{d}->visitName($self) if (exists $node->{d});
	$node->{s}->visitName($self) if (exists $node->{s});
}

#
#	3.11	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);				# single or array
	}
}

#
#	3.12	Operation Declaration
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self);		# param_type_spec or void
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);				# parameter
	}
}

sub visitNameParameter {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self);		# param_type_spec
}

sub visitNameVoidType {
	# empty
}

#
#	3.13	Attribute Declaration
#

sub visitNameAttributes {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);				# attribute
	}
}

sub visitNameAttribute {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self);		# param_type_spec
}

1;

