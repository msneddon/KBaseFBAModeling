########################################################################
# Bio::KBase::ObjectAPI::GenomeComparison::blast_proteomes_params - This is the moose object corresponding to the GenomeComparison.blast_proteomes_params object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-17T05:19:37
########################################################################
use strict;
use Bio::KBase::ObjectAPI::GenomeComparison::DB::blast_proteomes_params;
package Bio::KBase::ObjectAPI::GenomeComparison::blast_proteomes_params;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::GenomeComparison::DB::blast_proteomes_params';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************



#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
