#!/usr/bin/env perl
if ($0 =~ /([^(\/)]+)$/) {
    push (@INC, "$`lib/");
}
#require "cgi-lib.pl";
use CGI;
use CGI::Carp qw/fatalsToBrowser/;
#### redirect error log to a file
BEGIN {
    $ERR_LOG = "/dev/null";
#    $ERR_LOG = &RSAT::util::get_pub_temp()."/RSA_ERROR_LOG.txt";
    use CGI::Carp qw(carpout);
    open (LOG, ">> $ERR_LOG")
	|| die "Unable to redirect log\n";
    carpout(*LOG);
}
require "RSA.lib";
require "RSA2.cgi.lib";
$ENV{RSA_OUTPUT_CONTEXT} = "cgi";

### Read the CGI query
$query = new CGI;

### print the header
&RSA_header("create-background-model result", 'results');

## Check security issues
&CheckWebInput($query);

## update log file
&UpdateLogFile();

&ListParameters() if ($ENV{rsat_echo} >= 2);

#$command = "$SCRIPTS/oligo-analysis -v 1 -quick ";
$command = $SCRIPTS."/create-background-model -v 1 "; 
$prefix = "create-bg";
$tmp_file_path = &RSAT::util::make_temp_file("",$prefix, 1); ($tmp_file_dir, $tmp_file_name) = &SplitFileName($tmp_file_path);
@result_files = ();

#### read parameters ####
my $parameters;

#### default options ####
# $parameters .= " -1str -return freq,occ ";

### sequences ###
($sequence_file, $sequence_format) = &MultiGetSequenceFile(1, $tmp_file_path.".fasta", 1);
$parameters .= " -i $sequence_file ";

################################################################
## Background model method

my  $markov_order = $query->param('markov_order');
&RSAT::error::FatalError("Markov model should be a Natural number") unless &IsNatural($markov_order);
# my $oligo_length = $markov_order+1;
# $parameters .= " -l ".$oligo_length;
#  if ($query->param('noov')) {
#    $parameters .= " -noov ";
#  }

$parameters .=  " -markov ".$markov_order;  
 
################################################################
## Output format
my $output_format = lc($query->param('output_format'));
$parameters .= " -out_format ".$output_format;


## Output file
$result_file = $tmp_file_path;
push @result_files, "Background model file", $result_file;

&ReportWebCommand($command." ".$parameters);

### execute the command ###
if ($query->param('output') eq "display") {
#    &PipingWarning();

 ## prepare figures
    ### prepare data for piping
    open RESULT, "$command $parameters |";

  ### prepare data for piping
  open RESULT, "$command $parameters |";

  ### open the sequence file on the server
  if (open MIRROR, ">$result_file") {
    $mirror = 1;
    &DelayedRemoval($result_file);
  }

    print "<PRE>";
    while (<RESULT>) {
     # print "$_" unless ($query->param('output') =~ /server/i);
      print MIRROR $_ if ($mirror);
      if ($_ =~ /Error<\/h4><blockquote/ ) {
	$error_found = 1;
      }	
    }
    print "</PRE>";
    close RESULT;
    close MIRROR if ($mirror);

   
    &PrintURLTable(@result_files);
#    &PipingForm(); ## NOT WORKING YET (2019-12-11)

    print "<HR SIZE = 3>";

} else {
    &EmailTheResult("$command $parameters", $query->param('user_email'), $result_file);
}
print $query->end_html;


# ### prepare data for piping
# sub PipingForm {
#   local $matrix_content = `cat $tab_matrices`;
#   $matrix_content =~ s|//\n||gm;
#   $matrix_content =~ s|;.*\n||gm;
# #  print "<pre>".$command."</pre>";
# #  print "<pre>".$matrix_content."</pre>";


#   ## Compute the URL of the result file
#   $result_url = $result_file;
#   $result_url =~ s|$ENV{RSAT}/public_html|$ENV{rsat_www}|;

#     print <<End_of_form;
# <hr size="3">
# <table class="Nextstep">
# <tr>
# <td colspan="3">
# <h3>Next step</h3>
# </td>
# </tr>

# <tr>
# <td valign="bottom" align="center">
# <form method="POST" action="convert-background-model_form.cgi">
# <input type="hidden" name="bg_format" value="${output_format}">
# <input type="hidden" name="bg_method" value="file_url">
# <input type="hidden" name="bgmodel_url" value="${result_url}">
# <input type="submit" value="convert-background-model">
# </form>
# </td>
# </tr>


# </table>
# End_of_form

#   $title = $query->param('title');

# }

exit(0);

