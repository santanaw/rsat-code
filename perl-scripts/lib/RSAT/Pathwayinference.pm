#!/usr/bin/perl -w
############################################################
#
# $Id: Pathwayinference.pm,v 1.3 2012/03/14 11:51:12 rsat Exp $
#
############################################################

## use strict;

=pod

=head1 Extract Pathway from gene list

=head1 VERSION 1.0

=head1 DESCRIPTION

This tool is a Perl Wrapper around the stand-alone application
(PathwayInference) developed by Karoline Faust.

The PathwayInference tool can also be used via the Web interface
"Pathway Extraction" (http:// rsat.ulb.ac.be/neat).

The Perl wrapper performs several steps to enable the extraction of
pathways from sets of functionally related genes (e.g. co-expressed,
co-regulated, members of the same operon, …).

1. Gene to reaction mapping. Identify the set of reactions ("seed
reactions") catalyzed by the set of input genes ("seed genes"). The
mapping relies on a user-specified file describing the mapping of
genes to reactions (GNN and NNN, Gene-Node Name and Network Node Name<>NodeID file).

2. Pathway extraction (=Pathway inference). PathwayInference takes as
input a network (typically a metabolic network made of compounds +
reactions) and a set of "seed" nodes. The program attempts to return a
subnetwork that interconnects the seed nodes at a minimal “cost",
where the cost is a weighted sum of the intermediate compounds and
reactions used to link the seed nodes (Faust, et al., 2011; Faust and
van Helden, 2011).

This implementation requires no database or Internet connection and
works with local files only.  The PathwayInference tool wraps a number
of algorithms to infer pathways: k shortest paths (REA), kWalks and a
hybrid approach combining both (Faust, et al., 2010). In addition, two
Steiner tree algorithms are available (Takahashi-Matsuyama and
Klein-Ravi), each of them alone or in combination with kWalks.

=head1 AUTHORS

The java PathwInference tool was developed by Karoline Faust. This
Perl wrapper was developed by Didier Croes. The doc was written by
Didier Croes and Jacques van Helden.

=head1 REFERENCES

Faust, K., Croes, D. and van Helden, J. (2011). Prediction of
metabolic pathways from genome-scale metabolic networks. Biosystems.

Faust, K., Dupont, P., Callut, J. and van Helden, J. (2010). Pathway
discovery in metabolic networks by subgraph extraction. Bioinformatics
26, 1211-8.

Faust, K. and van Helden, J. (2011). Predicting metabolic pathways by
sub-network extraction.  Methods in Molecular Biology in press, 15.

=head1 CATEGORY

Graph tool

=head1 USAGE

pathway_extractor -h -hp [-i inputfile] [-o output_directory] [-v verbosity] \
    -g infile{graph} -a gene2ec -b ec/rxn/cpd2rxnid/cpdid [-d unique_descriptor] [-t temp_directory] [-show]

=head1 INPUT FORMAT

Warning: the same gene identifiers should be used in all input files.

=head2 1) List of seed genes (gene identifiers):

(Warning at least 2 gene ids must be present in the graph file see
below) in this example we use gene IDs. Beware, the gene IDs must be
compatible with the genome version installed on RSAT. Depending on the
organism source, the IDs can correspond to RefSeq, EnsEMBL, or other
references.

Example of seed gene file:
NP_414739
NP_414740
NP_414741
NP_416617
NP_417417
NP_417481
NP_418232
NP_418272
NP_418273
NP_418373
NP_418374
NP_418375
NP_418376
NP_418437
NP_418443

----------------------------------------------------------------

=head2 2)Graph file format:

see Pathwayinference tools helppathway_extractor

java graphtools.algorithms.Pathwayinference –h

The same result can be obtained by typing

pathway-extractor -hp

----------------------------------------------------------------



=head2 Seed mapping file

The seed mapping file makes the link between different types of seeds
(genes, EC numbers, proteins, compound names) and nodes of the network
(reactions or compounds depending on the seed type).

=head3 Network Node Names (nnn) file (option I<-nnn>)

Mandatory.

The NNN files makes the link between EC numbers/rxn name/cpd name and node id in the network .

These files are used for the reaction ids/compound ids to gene annotation (backward).


=head3 Example of NNN file

 #query  id      qualifier       name
1.-.-.- RXN1G-1486      EC      3-oxo-C78-α-mycolate-reductase
1.-.-.- RXN1G-1527      EC      3-oxo-C85-cis-methoxy-mycolate reductase
1.-.-.- RXN1G-1528      EC      3-oxo-C86-trans-methoxy-mycolate-reductase
10-deoxysarpagine       10-DEOXYSARPAGINE       compounds       10-deoxysarpagine
10-DEOXYSARPAGINE       10-DEOXYSARPAGINE       compounds       10-deoxysarpagine
 ...

=head3 Gene to Node Names (gnn) file (option I<-gnn>)

not mandatory, in this cas the queyr file or stdin must contains only Node Names.

The GNN files makes the link between external identifier and node names (example: gene name, refseq, locuslink) . 


=head3 Example of NNN file

#query	id	qualifier	name	taxonomy_id	species
aas	2.3.1.40	GENE_NAME	aas	83333	Escherichia coli (strain K12)
aas	6.2.1.20	GENE_NAME	aas	83333	Escherichia coli (strain K12)
aat	2.3.2.6	GENE_NAME	aat	83333	Escherichia coli (strain K12)


=head1 EXAMPLES

=head2 With an input file

=head3 Motivation

Get methionine-related genes in Escherichia coli genome. This
generates a file containing one line per gene and one column per
attribute (ID, start, end, name, ...).


=head3 Commands

Extract all E.coli genes whose name starts with met
 gene-info -org Escherichia_coli_K_12_substr__MG1655_uid57779 -feattype CDS -full -q '^met.*' -o met_genes.tab

Select the first column, containing gene Ids.
 grep -v "^;" met_genes.tab | cut -f 1 > met_genes_IDs.txt

Extract a pathway connecting at best the reactions catalyzed by these gene products
  pathway-extractor -i met_genes_IDs.txt \
     -g data/networks/MetaCyc/MetaCyc_directed_141.txt \
     -gnn ${RSAT}/data/metabolic_networks/GER_files/GPR_Uniprot_112011_Escherichia_coli_K12.tab \
     -o result_dir \
     -t temp_dir

----------------------------------------------------------------

=head2 Using standard input

=head3 The script pathway-extractor can also use as input the STDIN. This allows to use it in aconcatenation of commands. For example, all the commands above could be combined in a single pipeline as follows.

 gene-info -org Escherichia_coli_K_12_substr__MG1655_uid57779 -feattype CDS -q 'met.*' \
   | grep -v "^;" met_genes.tab | cut -f 1 \
   | pathway-extractor -g data/networks/MetaCyc/MetaCyc_directed_141.txt \
       -ger data/networks/MetaCyc/METACYC_GPR_EC_20110620.txt \
       -o result_dir -t temp_dir

----------------------------------------------------------------

=head1 OUTPUT FILES:

*_converted_seeds.txt : pathway inference input file.

*_pred_pathways.txt : result graph file of the pathway inference

*_annot_pred_pathways.txt : : result file of the pathway inference with gene and EC annotation

*_annot_pred_pathways.dot : result file in dot format, which can be converted to a figure using the
automatic layout program dot (included in the software suite graphviz).

*._annot_pred_pathways.png : png image file of the inferred pathway
----------------------------------------------------------------

=cut


BEGIN {
    if ($0 =~ /([^(\/)]+)$/) {
	push (@INC, "$`lib/");
	push (@INC,"$ENV{RSAT}/perl-scripts/lib/");
    }
}
require "RSA.lib";
use RSAT::util;


################################################################
## pathwayinference package
package RSAT::Pathwayinference;

# {  
#   #other pathwayinference otptions : specific opions that will be directly pass to the java pathway inference app
#   our @pioptions=('-s','-i','-g','-f','-b','-n','-q','-o','-O','-E','-a','-y','-p','-F','-Z','-m','-w','-t',
# 		  '-l','-T','-W','-P','-C','-e','-d','-u','-x','-k','-U','-B','-r','-D','-M','-I','-N','-G',
# 		  '-H','-X','-A','-K','-S','-R','-j','-J','-Q','-L','-Y','-v','-h','-V'); 
#   our %otherPIoptions=();
#    ## Input/output files
#   our %infile = ();	     # input file names container
#   our %outfile = ();	     # output file names container
# 
#   ## Directories
#   our %dir = ();
#   $dir{output} = "."; # output directory
#   $dir{temp}= "";     # temporary directory
# 
#   our $verbose = "3";
#   our $in = STDIN;
#   our $out = STDOUT;
# 
#   $infile{gnn} =""; # GPR Gene -> EC -> REACTION annotation file path. Default (METACYC_GPR_EC.tab)
#   $infile{nnn}=""; 
#   $infile{graph}="";		# File containing the graph
# 
#   our $graph = "";		# Graph Name
#   our $group_descriptor= ""; # Unique name to differenciate output files
#   
#    ################################################################
#   ## Read argument values
#   &ReadArguments();
# 
#    ################################################################
#   ## Check argument values
#   
#   my $input = $infile{input};
#   my $isInputFile=0;
#   if ($input){
#     $isInputFile=1;
#   }else{
#     my @query_id_list = <$in>;
#     chomp(@query_id_list);
#     $input = join("\t", @query_id_list);
#   }
#   &RSAT::message::Info("--INPUT ", $input) if ($verbose >= 3);
#    &Inferpathway($input,$isInputFile, $dir{output},$infile{gnn},$infile{nnn},$infile{graph},$dir{temp},$group_descriptor,\%otherPIoptions);
# # &Inferpathway();
# }

sub Inferpathway{

  ################################################################
  ## Initialise parameters
  #
  local $start_time = &RSAT::util::StartScript();
  $program_version = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
  #    $program_version = "0.00";
   my $query_ids;
  my @query_id_list;
   my ($input,
       $isinputfile,
       $outputdir,
       $gnnfile,
       $nnnfile,
       $graphfile,
       $tempdir,
       $localgroup_descriptor,
       $verbose,
       $piparameters) = @_;
       
my %localotherPIparameters = %{$piparameters} if ($piparameters);
#   if the parameters comes from the function use those one
#   $dir{output} = $outputdir if ($outputdir);    
#   $dir{temp} = $tempdir if ($tempdir);
#   $infile{gnn} = $gnnfile if ($gnnfile);
#   $infile{nnn} = $nnnfile if ($nnnfile); 
#   $infile{graph} = $graphfile if ($graphfile);
#  
 
  if ($isinputfile){
    ($in) = &RSAT::util::OpenInputFile($input);
     
    @query_id_list = <$in>;
    close $in;
    #   if no group descriptor use the input file name
    if (!$localgroup_descriptor) {
      $localgroup_descriptor = $input;
      $localgroup_descriptor =~ s{.*/}{};     # removes path
      $localgroup_descriptor=~ s{\.[^.]+$}{}; # removes extension
    }
    
  }elsif ($input){
     @query_id_list = split(/\t|\s|;/,$input);
  }else{
    @query_id_list = <$in>;
  }
#close $in;
  if (!$localgroup_descriptor) {
      $localgroup_descriptor ="stdin";
  }
 
  
  $localgroup_descriptor=~s/(\s|\(|\))+/_/g;
 
 
  
  # if no graph name take the graph file name
  if (!$graph) {
    $graph = $graphfile;
    $graph =~ s{.*/}{};	    # removes path
    $graph=~ s{\.[^.]+$}{};   # removes extension
  }
  $graph=~s/(\s|\(|\))+/_/g;
 
  my $organism = "Unknown";
  my $organism_id;
  # my $working_dir = "";

  ################################################################
  ## Print verbose
#   &Verbose() if ($verbose);

  ################################################################
  ## Execute the command

  ## Check the existence of the output directory and create it if
  ## required
  unless ($outputdir =~ /\/$/) {
   $outputdir =$outputdir."/";
  }
 $outputdir =~s |//|/|g; ## Suppress double slashes
  &RSAT::util::CheckOutDir($outputdir);

  ## Check the existence of the temp directory and create it if
  ## required
  $tempdir=$outputdir unless ($tempdir);
  if (!($tempdir=~m/\/$/)) {
    $tempdir = $tempdir."/";
  }
  &RSAT::util::CheckOutDir($tempdir);



  ################################################################
  ## ECR Mapping

  ## DIDIER: the ECR mapping should be redone with the new program match-names.

  &RSAT::message::TimeWarn("Mapping seeds to reactions") if ($verbose >= 1);
  
  chomp(@query_id_list);
  $query_ids = (join "\$|^",@query_id_list );	# build a query from the input file or stdin
  &RSAT::message::Info("Query IDs", join("; ", @query_id_list)) if ($verbose >= 3);

  my @ercconversiontable;
  my %querylist=();
  ## search into the GEC or GR file to find EC or Reactionid from gene input
  my $seed_converter_cmd = "awk -F'\\t+' '\$1~\"^".$query_ids."\" {print \$2\"\\t\"\$1\"\\t\"\$3\"\\t\"\$4}' \"$gnnfile\"";

  &RSAT::message::TimeWarn("Seed conversion:", $seed_converter_cmd) if ($verbose >= 2);

  if($gnnfile){
    my @gnnconversiontable = qx ($seed_converter_cmd) ;
    chomp(@gnnconversiontable);
    foreach my $line (@gnnconversiontable){
      @tempdata = split(/\t/,$line);
      $query_ids .= "\$|^".$tempdata[0]; # complete the query with id found in gnn file
    }
  }
  # search in the ECR file with the complete query this normaly map ec, compound and reaction_id already presenet in the query
  $seed_converter_cmd = "awk -F'\\t+' '\$1~\"^".$query_ids."\" {print \$1\"\\t\"\$2\"\\t\"\$3\"\\t\"\$4}' \"$nnnfile\"";
   &RSAT::message::TimeWarn("Seed conversion:", $seed_converter_cmd) if ($verbose >= 2);
  my @conversiontable = qx ($seed_converter_cmd) ;
  chomp(@conversiontable);
  &RSAT::message::Info("Predicted pathway file\n", join("\n", @conversiontable)) if ($verbose >= 1);
  
# getting organism information
# End of ECR mapping
################################################################
  if (! defined $group_id) {
  $groupid =$localgroup_descriptor;
  }
  $groupid=~s/(\s|\(|\))+/_/g;
  
  ################################################################
  ## Define output file names
  $outfile{gr} = "";		# GR Gene -> REACTION annotation
  $outfile{prefix} =$outputdir."/";
  $outfile{prefix} .= join("_", $localgroup_descriptor, $groupid, $graph, "pred_pathways");
  $outfile{prefix} =~ s|//|/|g; ## Suppress double slashes

  $outfile{predicted_pathway} = $outfile{prefix}.".txt";
  $outfile{seeds_converted} = $outfile{prefix}."_seeds_converted.txt";
  ################################################################
  # Creating reaction file fo pathway inference
  &RSAT::message::TimeWarn("Creating reaction file for pathway inference") if ($verbose >= 1);
#  my $outfile{seeds_converted} =$outputdir.(join "_",$localgroup_descriptor,$groupid,$graph, "_converted_seeds.txt");
  open (MYFILE, '>'.$outfile{seeds_converted});
  print MYFILE "# Batch file created", &RSAT::util::AlphaDate();
  print MYFILE "# ECR groups parsed from file:". "\n";
  print MYFILE "# EC number grouping: true". "\n";
  my $seednum= 0;
  my @previousarray;
  foreach my $val (@conversiontable) {

    @tempdata = split(/\t/,$val);
    if (@previousarray && !($tempdata[0] eq $previousarray[0])) {
      print MYFILE "$previousarray[0]\t$groupid\n";
      $seednum++;
    }
    # 	print "$tempdata[1] eq $previousarray[1]\n";
    print MYFILE $tempdata[1] .">\t".$tempdata[1]. "\n";
    print MYFILE $tempdata[1] ."<\t".$tempdata[1]. "\n";
    print MYFILE $tempdata[1] ."\t".$tempdata[0]. "\n";
    @previousarray = @tempdata;
  }

  if (@conversiontable) {
    print MYFILE "$previousarray[0]\t$groupid\n";
    $seednum++;
  }
  # END OF  Creating reaction file fo pathway inference
  ################################################################
## TO DO WITH DIDIER: CHECK SEED NUMBER AND SEND WARNING IF TOO BIG.
  ##
  ## Define a parameter max{seed_numbers}. By default, program dies
  ## with error if seeds exceed max{seed_number}, but the max can be
  ## increased by the user with the option -max seeds #.

  if ($seednum > 1) {
    ################################################################
    # Running PatywayInference
    &RSAT::message::TimeWarn("Running pathway inference with ", $seednum, "seeds") if ($verbose >= 1);
#    $outfile{predicted_pathway} =$outputdir.(join "_",$localgroup_descriptor, $groupid, $graph, "_pred_pathways.txt");
    our $minpathlength = $otherPIoptions{"-m"} || "5";
    delete($otherPIoptions{"-m"});
    our $graphfileformat = $otherPIoptions{"-f"} || "flat";
    delete($otherPIoptions{"-f"});
    our $weightpolicy= $otherPIoptions{"-y"} || "con";
    delete($otherPIoptions{"-h"});
    delete($otherPIoptions{"-g"});
    delete($otherPIoptions{"-o"});
    delete($otherPIoptions{"-p"});
    delete($otherPIoptions{"-v"});
    #after the program has handled the mandatory parameters, it will add the remaining ones 
    my $piparameters =" ";
    
    while( my($key, $val) = each(%localotherPIparameters) ) {
	$piparameters .= "$key $val ";
    }
    
    
    my $pathway_infer_cmd = "java -Xmx1000M graphtools.algorithms.Pathwayinference";
    $pathway_infer_cmd .= " -i ".$outfile{seeds_converted};
    $pathway_infer_cmd .= " -m $minpathlength -C -f $graphfileformat";
    $pathway_infer_cmd .= " -p ".$tempdir;
    $pathway_infer_cmd .= " -E ".$outputdir;
    $pathway_infer_cmd .= " -d -b -g ";
    $pathway_infer_cmd .= " ".$graphfile;
    $pathway_infer_cmd .= " -y $weightpolicy -v ".$verbose;
    $pathway_infer_cmd .=  $piparameters;
    
    $pathway_infer_cmd .= "-o $outfile{predicted_pathway}";
    
    
    &RSAT::message::TimeWarn("Pathway inference command", $pathway_infer_cmd) if ($verbose >= 2);
    &RSAT::message::Info("Predicted pathway file", $outfile{predicted_pathway}) if ($verbose >= 1);
    #exit 1;
    &RSAT::util::doit($pathway_infer_cmd, $dry, $die_on_error, $verbose, $batch, $job_prefix);

    ## TO DO WITH DIDIER: redirect STDERR/STDOUD to log and err files in the output directory

    # END of Running patywayinference
    ################################################################
  } else {
    print STDERR "NOT ENOUGH SEEDS. Min 2. I stop here!!\n";
    exit(1);
  }
  # End of Converting dot graph to image with graphviz dot
  ################################################################

  ################################################################
  ## Insert here output printing
  ## Report execution time and close output stream
  &RSAT::message::TimeWarn("Ending") if ($verbose >= 1);
   my $exec_time = &RSAT::util::ReportExecutionTime($start_time); ## This has to be exectuted by all scripts
   print $exec_time if ($verbose); ## only report exec time if verbosity is specified
#   close $out if ($outfile{output});

 return $outfile{predicted_pathway};
}


sub ProcessOutputFiles{
my ($inputfile,
   $outputdir,
   $gnnfile,
   $nnnfile,
   $verbose) = @_;
  
  my %outfile = ();
  $outfile{prefix} = $outputdir."/";
  my $outputfile =  $inputfile;
  $outputfile =~ s{.*/}{};# remove path
  $outputfile =~ s{\.[^.]+$}{};# remove file extension
  $outfile{prefix} =~ s|//|/|g; ## Suppress double slashes
  print  $outfile{prefix}."\n";
  $outfile{prefix} .= $outputfile;
  $outfile{graph_png} = $outfile{prefix}."_annot.png";
  $outfile{graph_dot} = $outfile{prefix}."_annot.dot";
  $outfile{graph_annot} = $outfile{prefix}."_annot.txt";
  print  $outfile{graph_annot}."\n";
  
    ################################################################
    # Loading reactions from extracted  graph
    
#     &RSAT::message::TimeWarn("Loading reactions from extracted graph") if ($verbose >= 1);
    open (INFILE, '<'.$inputfile) or die "couldn't open the file!";
    my $i = 0;
    my $stop = "";
    my $line;
    my $reactioncpdquery="";
    while ($line=<INFILE>) {
      #$line = $_;
      chomp  ($line );
      if (length($line)>0 && !($line=~m/^;/)) {
	my @tempdata = split(/\t/,$line);
	if ($tempdata[6] &&(($tempdata[6] eq "Reaction")|| ($tempdata[6] eq "Compound"))) {
	  #       print "|".$line."|"."\n";
	  $tempdata[0]=~s/<$|>$//;
	  $i++;
	  $reactioncpdquery = $reactioncpdquery."(\$2~\"^$tempdata[0]\")||";
	}
      } elsif ($i>0) {
	last;
      }
    }
    close (INFILE);
    # End of Loading results graph reactions
    ################################################################

    ################################################################
    # Searching all reactions information for the reaction that are in  the inferred pathway graph
    &RSAT::message::TimeWarn("Searching information about extracted reactions") if ($verbose >= 1);
    $reactioncpdquery =~s/\|+$//;
   

    my $command_ = "awk -F'\\t+' ' $reactioncpdquery {print \$2\"\\t\"\$1\"\\t\"\$3\"\\t\"\$4}' $nnnfile|sort|uniq";
#    print "$command_\n";
    &RSAT::message::TimeWarn($command_) if ($verbose >= 1);
    my @conversiontable = qx ($command_);
    chomp(@conversiontable);

    ## Storing reaction infos in a hash for faster search
    my %reactioninfos=();
    undef @previousarray;
    my @reacinfoarray=();
    foreach my $content (@conversiontable) {
      my @currentarray = split(/\t/,$content);
      if ( @previousarray && !($previousarray[0] eq $currentarray[0])) {
	# 	  print $previousarray[0]."\n";
	my @truc = @reacinfoarray;
	$reactioninfos{$previousarray[0]}=\@truc;
	undef @reacinfoarray;
      }
      push (@reacinfoarray,\@currentarray);
      @previousarray = @currentarray;
    }
    $reactioninfos{$previousarray[0]}=\@reacinfoarray;
    
    ## if gene file get ECs from conversion table
    my %gnninfos=();
    undef @previousarray;
    my @gnninfoarray=();
    if ($gnnfile){
      my $ec2genequery="";
      while(my ($rxnid, $infoarray) = each(%reactioninfos)) {
	my @values = @{$infoarray};
	foreach my $info_ref (@values) {
	  my @info = @{$info_ref};  
	  if($info[2] eq "EC"){
	    &RSAT::message::Info("EC2GENE:", $info[0]) if ($verbose >= 3);
	    $ec2genequery = $ec2genequery."(\$2~\"^$info[1]\")||"
	  }
	}
      }
       $ec2genequery =~s/\|+$//;
      
      #buid an hash for ec 2 genes
      
      $command_ = "awk -F'\\t+' ' $ec2genequery {print \$2\"\\t\"\$1\"\\t\"\$3\"\\t\"\$4}' \"$gnnfile\"|sort|uniq";
      &RSAT::message::TimeWarn($command_) if ($verbose >= 1);
      my @gnnonversiontable = qx ($command_);
      foreach my $content (@gnnonversiontable) {
# 	&RSAT::message::Info("EC2GENE:", $content) if ($verbose >= 3);
	my @currentarray = split(/\t/,$content);
	if ( @previousarray && !($previousarray[0] eq $currentarray[0])) {
	# 	  print $previousarray[0]."\n";
	  
	  my @truc = @gnninfoarray;
	  &RSAT::message::Info("ECS2GENE:", $previousarray[0] ."\t" . $truc[0][1]) if ($verbose >= 3);
	  $gnninfos{$previousarray[0]}=\@truc;
	  undef @gnninfoarray;
	}
# 	&RSAT::message::Info("GENE:", $previousarray[0]) if ($verbose >= 3);
	push (@gnninfoarray,\@currentarray);
	@previousarray = @currentarray;
      }
      $gnninfos{$previousarray[0]}=\@gnninfoarray;
      
       &RSAT::message::Info("GENE:", "|".$previousarray[0] ."|\t" . $gnninfos{"5.3.1.16"}[0][1]) if ($verbose >= 3);
    }
#     exit 1;
 

    # End of Searching all reactions information for the reaction that are in  the infered pathway graph
    ################################################################

    ################################################################
    # Adding description to the pathway graph
    &RSAT::message::TimeWarn("Adding descriptions to pathway graph") if ($verbose >= 1);
    open (INFILE, '<'.$inputfile) or die "couldn't open the file!";
#    my $outfile{graph_annot} = $outputdir.(join "_",$group_descriptor, $groupid, $graph, "annot_pred_pathways.txt");
    # my $outfilename = `mktemp $outfile{graph_annot}`;
    open (OUTFILE, '>'.$outfile{graph_annot}) or die "couldn't open the file!";
    #     print $group_descriptor;
    while (<INFILE>) {
      my($line) = $_;
      chomp($line);
      my @tempdatab = split(/\t/,$line);
      if (length($line)==0 || $line=~ m/^;/) {
	print OUTFILE $line. "\n";
      } else {

	my $tempstring = $tempdatab[0];
	$tempstring=~s/<$|>$//;
	$tempdatab[0] = $tempstring; #remove directionality from reaction node id to merge the nodes
	# 	      print "TEMPSTRING = $tempstring\n";
	my $values_ref = $reactioninfos{$tempstring};
	if (defined $values_ref) {
	  my @values = @{$values_ref};
	  if ($tempdatab[6] && ($tempdatab[6] eq "Reaction")) {

	    my $label="";
	    my $labelb;
	    my $ecs;
	    my $reactionid;
	    foreach my $info_ref (@values) {
	      my @info = @{$info_ref};

	      #  	      print "JOIN=".join("\t", $myarray[0][0])."\n";
	      my($reacid,$ec,$qualif) = @info;
	      # 		    print "ec: $ec\n";
	      if ($ec) {
		if ($qualif eq "EC"){
		  if (%gnninfos){
		    chomp($ec);
		    my $genes = $gnninfos{$ec};
		    &RSAT::message::Info("EC:", "|".$ec."|",  $gnninfos{"$ec"}[0][1]) if ($verbose >= 4);
		    if (defined $genes) {
		      my @genesarray = @{$genes};
		      foreach my $genearrayref (@genesarray) {
			my @genearray = @{$genearrayref};
			my($id,$genename,$qualif) = @genearray;		  
			chomp($genename);
			$label.= "$genename,";
		      }
		    }
		  }
		  $ecs .= $ec;
		}
		if (!defined $reactionid) {
		  $reactionid = $reacid;
		}
	      }
	    }
	    $labelb = "\\n$ecs\\n($reactionid)";
	    
	    $tempdatab[3] = $label.$labelb;
	  } elsif ($tempdatab[6] &&($tempdatab[6] eq "Compound")) {
	    $tempdatab[3] =  $values[0][1];
	  } else {
	    $tempdatab[1]=~s/<$|>$//;
	  }
	}
	print OUTFILE (join "\t",@tempdatab). "\n";
      }
    }
    close (OUTFILE);
    # End of Adding description to the pathway graph
    ################################################################

    ################################################################
    # Converting graph to dot format
    &RSAT::message::TimeWarn("Converting graph to dot format") if ($verbose >= 1);
#    my $outfile{graph_dot} = $outputdir.(join "_",$group_descriptor, $groupid, $graph, "annot_pred_pathways.dot");
     
    my $convert_graph_cmd = "convert-graph -from path_extract -to dot -i $outfile{graph_annot} -o $outfile{graph_dot} $undirected";
    system  $convert_graph_cmd;
    # End of Converting graph to dot graph format
    ################################################################

    ################################################################
    # Converting dot graph to image with graphviz dot
    &RSAT::message::TimeWarn("Creating graph image with graphviz dot") if ($verbose >= 1);
#    my $outfile{graph_png} = $outputdir.(join "_",$group_descriptor, $groupid, $graph, "annot_pred_pathways.png");
    my $graph_image_cmd = "dot -Tpng -Kdot -o $outfile{graph_png} $outfile{graph_dot}";
    system $graph_image_cmd;
    #exit 0;
    if ($show) {
      system "gwenview $outfile{graph_png} &";
    }
 
  # End of Converting dot graph to image with graphviz dot
  ################################################################

  ################################################################
  ## Insert here output printing
  ## Report execution time and close output stream
  &RSAT::message::TimeWarn("Ending") if ($verbose >= 1);
  my $exec_time = &RSAT::util::ReportExecutionTime($start_time); ## This has to be exectuted by all scripts
  print  $exec_time if ($verbose); ## only report exec time if verbosity is specified
 
}
################################################################
################### SUBROUTINE DEFINITION ######################
################################################################



# ################################################################
# ## Display full help message
# sub PrintHelp {
#   system "pod2text -c $0";
#   exit()
# }
# 
# ################################################################
# ## Display short help message
# sub PrintOptions {
#   &PrintHelp();
# }
# 
# ################################################################
# ## Read arguments
# sub ReadArguments {
#   my $arg;
#   my @arguments = @ARGV; ## create a copy to shift, because we need ARGV to report command line in &Verbose()
#   while (scalar(@arguments) >= 1) {
#     $arg = shift (@arguments);
#     ## Verbosity
# 
# =pod
# 
# =head1 OPTIONS
# 
# =over 4
# 
# =item B<-v>
# 
# Verbose mode
# 
# =cut
#     if ($arg eq "-v") {
#       if (&RSAT::util::IsNatural($arguments[0])) {
# 	$verbose = shift(@arguments);
#       } else {
# 	$verbose = 1;
#       }
# 
# 
# =pod
# 
# =item B<-h>
# 
# Display full help message
# 
# =cut
#     } elsif ($arg eq "-h") {
#       &PrintHelp();
# 
# 
# =pod
# 
# =item B<-help>
# 
# Same as -h
# 
# =cut
#     } elsif ($arg eq "-help") {
#       &PrintOptions();
# 
# =pod
# 
# =item B<-hp>
# 
# Display full PathwayInference help message
# 
# =cut
#     } elsif ($arg eq "-hp") {
#       system("java graphtools.algorithms.Pathwayinference -h");
#       print "\n";
#       exit(0);
# 
# =pod
# 
# =item B<-show>
# 
# execute gwenview to display the pathway results in png format
# 
# =cut
#     } elsif ($arg eq "-show") {
#      $show = 1;
# 
# =pod
# 
# =item B<-i inputfile>
# 
# If no input file is specified, the standard input is used.  This
# allows to use the command within a pipe.
# 
# =cut
#     } elsif ($arg eq "-i") {
#       $infile{input} = shift(@arguments);
# 
# =pod
# 
# =item	B<-gnn GE Genes file>
# 
# Gene -> EC (GE) annotation file.
# 
# =cut
#     } elsif ($arg eq "-gnn") {
#       $infile{gnn} = shift(@arguments);
# =pod
# 
# =item	B<-nnn ECR file>
# 
# EC -> REACTION and COUMPOUNDS (ECR) annotation file.
# 
# =cut
#     } elsif ($arg eq "-nnn") {
#       $infile{nnn} = shift(@arguments);      
# # =item	B<-b GR Gene -> REACTION annotation>
# #
# # An gene annotation file with diredt link gene to reaction. Does not rely on the EC number annotation
# #
# #
# # =pod
# #
# # =cut
# #     } elsif ($arg eq "-b") {
# #       $outfile{gr} = shift(@arguments);
# 
# # =pod
# 
# # =item	B<-n Graph name>
# #
# # Name of the Graph (default: Name of the graph file).
# #
# # =cut
# #     } elsif ($arg eq "-n") {
# #       $graph = shift(@arguments);
# #
# 
# =pod
# 
# =item	B<-gd group descriptor>
# 
# ??? (Check with Didier)
# 
# =cut
#     } elsif ($arg eq "-gd") {
#       $group_descriptor = shift(@arguments);
# 
# 
# =pod
# 
# =item	B<-d Unique descriptor>
# 
# Unique name to differenciate output files. If not set With -i, the name of the input file will be used.
# 
# =cut
#     } elsif ($arg eq "-g") {
#       $infile{graph} = shift(@arguments);
# 
# =pod
# 
# =item	B<-o output Directory>
# 
# If no output file is specified, the current directory is used.
# 
# =cut
#     } elsif ($arg eq "-o") {
#       $dir{output} = shift(@arguments);
# 
# =pod
# 
# =item	B<-p temp Directory>
# 
# If no output file is specified, the current directory is used.
# 
# =cut
#     } elsif ($arg eq "-p") {
#       $dir{temp} = shift(@arguments);
# =pod
# 
# =item	B<Pathway inference arguments>
# 
# =cut
#       
#     } elsif (grep(/$arg/ ,@pioptions)) { #if Pathway inference option add it to hash
#       $otherPIoptions{$arg}= shift(@arguments);
# #       $dir{temp} = shift(@arguments);
#     } else {
#       
#        &FatalError(join("\t", "Invalid pathway_extractor option", $arg));
# 
#     }
#   }
# #GetOptionsFromArray(\@arguments,\%localotherPIparameters)
# #getopts("CnHf:b:q:O:E:a:y:p:F:Z:m:w:t:l:T:W:P:e:d:u:x:k:U:B:r:D:M:I:N:G:X:A:K:S:R:j:J:Q:L:Y:v:h:V:o:p:g:i:g:",\%localotherPIparameters);
# #&FatalError(join("\t", "Invalid pathway_extractor option", $ARGV[0])) if $ARGV[0];
#       
# =pod
# 
# =back
# 
# =cut
# 
# }
# ################################################################
# ## Verbose message
# sub Verbose {
#     print $out "; template ";
#     &RSAT::util::PrintArguments($out);
#     printf $out "; %-22s\t%s\n", "Program version", $program_version;
#     if (%infile) {
# 	print $out "; Input files\n";
# 	while (my ($key,$value) = each %infile) {
# 	  printf $out ";\t%-13s\t%s\n", $key, $value;
# 	}
#     }
#     if (%outfile) {
# 	print $out "; Output files\n";
# 	while (my ($key,$value) = each %outfile) {
# 	  printf $out ";\t%-13s\t%s\n", $key, $value;
# 	}
#     }
# }


__END__