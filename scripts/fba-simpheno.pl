#!/usr/bin/env perl
########################################################################
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use warnings;
use Bio::KBase::workspace::ScriptHelpers qw( printObjectInfo get_ws_client workspace workspaceURL parseObjectMeta parseWorkspaceMeta printObjectMeta);
use Bio::KBase::fbaModelServices::ScriptHelpers qw(fbaws get_fba_client runFBACommand universalFBAScriptCode );
#Defining globals describing behavior
my $primaryArgs = ["Model ID","Phenotype set"];
my $servercommand = "simulate_phenotypes";
my $script = "fba-simpheno";
my $translation = {
	"Model ID" => "model",
	"Phenotype set" => "phenotypeSet",
	modelws => "model_workspace",
	phenows => "phenotypeSet_workspace",
	phenosimid => "phenotypeSimultationSet",
	fva => "fva",
	simko => "simulateko",
	minfluxes => "minimizeflux",
	findminmedia => "findminmedia",
	notes => "notes",
	workspace => "workspace",
	auth => "auth",
	overwrite => "overwrite",
	alltransporters => "all_transporters",
	positivetransporters => "positive_transporters",
	gapfillphenosim => "gapfill_phenosim",
	solver => "solver",
	biomass => "biomass"
};
my $fbaTranslation = {
	objfraction => "objfraction",
	allrev => "allreversible",
	maximize => "maximizeObjective",
	defaultmaxflux => "defaultmaxflux",
	defaultminuptake => "defaultminuptake",
	defaultmaxuptake => "defaultmaxuptake",
	simplethermo => "simplethermoconst",
	thermoconst => "thermoconst",
	nothermoerror => "nothermoerror",
	minthermoerror => "minthermoerror",
	prommodel => "prommodel",
	prommodelws => "prommodel_workspace",
	biomass => "biomass"
};
#Defining usage and options
my $specs = [
    [ 'phenosimid:s', 'ID for phenotype simulation in workspace' ],
    [ 'gapfillphenosim', 'Gapfill phenotype simulation' ],
    [ 'phenows:s', 'Workspace with phenotype data object' ],
    [ 'modelws:s', 'Workspace with model object' ],
    [ 'maximize:s', 'Maximize objective', { "default" => 1 } ],
	[ 'objterms:s@', 'Objective terms' ],
	[ 'geneko:s@', 'List of gene KO (; delimiter)' ],
	[ 'rxnko:s@', 'List of reaction KO (; delimiter)' ],
    [ 'bounds:s@', 'Custom bounds' ],
    [ 'constraints:s@', 'Custom constraints' ],
    [ 'prommodel|p:s', 'ID of PROMModel' ],
    [ 'prommodelws:s', 'Workspace with PROMModel', { "default" => fbaws() } ],
    [ 'defaultmaxflux:s', 'Default maximum reaction flux' ],
    [ 'defaultminuptake:s', 'Default minimum nutrient uptake' ],
    [ 'defaultmaxuptake:s', 'Default maximum nutrient uptake' ],
    [ 'uptakelim:s@', 'Atom uptake limits' ],
    [ 'simplethermo', 'Use simple thermodynamic constraints' ],
    [ 'thermoconst', 'Use full thermodynamic constraints' ],
    [ 'nothermoerror', 'No uncertainty in thermodynamic constraints' ],
    [ 'minthermoerror', 'Minimize uncertainty in thermodynamic constraints' ],
    [ 'allrev', 'Treat all reactions as reversible', { "default" => 0 } ],
    [ 'objfraction:s', 'Fraction of objective for follow on analysis', { "default" => 0.1 }],
    [ 'notes:s', 'Notes for flux balance analysis' ],
    [ 'workspace|w:s', 'Workspace to save FBA results', { "default" => fbaws() } ],
    [ 'overwrite|o', 'Overwrite any existing FBA with same name' ],
    [ 'alltransporters', 'Add transporters for everything in EVERY media in the phenotype set before doing the simulation' ],
    [ 'positivetransporters', 'Add transporters ONLY for media that the organism grows on in the phenotype set before doing the simulation' ],
    [ 'solver:s', 'Solver' ],
    [ 'biomass|b:s', 'Target biomass (bio1 is default)' ],
];
my ($opt,$params) = universalFBAScriptCode($specs,$script,$primaryArgs,$translation);
$params->{formulation} = {
	geneko => [],
	rxnko => [],
	bounds => [],
	constraints => [],
	uptakelim => {},
	additionalcpds => []
};
foreach my $key (keys(%{$fbaTranslation})) {
	if (defined($opt->{$key})) {
		$params->{formulation}->{$fbaTranslation->{$key}} = $opt->{$key};
	}
}
if (defined($opt->{objterms})) {
	foreach my $terms (@{$opt->{objterms}}) {
		my $array = [split(/;/,$terms)];
		foreach my $term (@{$array}) {
			my $termArray = [split(/:/,$term)];
			if (defined($termArray->[2])) {
				push(@{$params->{formulation}->{objectiveTerms}},$termArray);
			}
		}
	}
}
if (defined($opt->{geneko})) {
	foreach my $gene (@{$opt->{geneko}}) {
		push(@{$params->{formulation}->{geneko}},split(/;/,$gene));
	}
}
if (defined($opt->{rxnko})) {
	foreach my $rxn (@{$opt->{rxnko}}) {
		push(@{$params->{formulation}->{rxnko}},split(/;/,$rxn));
	}
}
if (defined($opt->{bounds})) {
	foreach my $terms (@{$opt->{bounds}}) {
		my $array = [split(/;/,$terms)];
		foreach my $term (@{$array}) {
			my $termArray = [split(/:/,$term)];
			if (defined($termArray->[3])) {
				push(@{$params->{formulation}->{bounds}},$termArray);
			}
		}
	}
}
if (defined($opt->{constraints})) {
	my $count = 0;
	foreach my $constraint (@{$opt->{constraints}}) {
		my $array = [split(/;/,$constraint)];
		my $rhs = shift(@{$array});
		my $sign = shift(@{$array});
		my $terms = [];
		foreach my $term (@{$array}) {
			my $termArray = [split(/:/,$term)];
			if (defined($termArray->[2])) {
				push(@{$terms},$termArray)
			}
		}
		push(@{$params->{formulation}->{constraints}},[$rhs,$sign,$terms,"Constraint ".$count]);
		$count++;
	}
}
if (defined($opt->{uptakelim})) {
	foreach my $uplims (@{$opt->{rxnko}}) {
		my $array = [split(/;/,$uplims)];
		foreach my $uplim (@{$array}) {
			my $pair = [split(/:/,$uplim)];
			if (defined($pair->[1])) {
				$params->{formulation}->{uptakelim}->{$pair->[0]} = $pair->[1];
			}
		}
	}
}
#Calling the server
my $output = runFBACommand($params,$servercommand,$opt);
#Checking output and report results
if (!defined($output)) {
	print "Phenotype simulation failed!\n";
} else {
	print "Phenotype simulation successful:\n";
	printObjectInfo($output);
}
